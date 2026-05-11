module Api
  module V1
    class RentPaymentsController < BaseController
      before_action :set_payment, only: %i[show mark_paid]

      def index
        payments = paginate(scoped_payments.includes(:lease, :tenant).recent)
        payments = payments.where(status: params[:status]) if params[:status].present?
        render json: payments, each_serializer: RentPaymentSerializer
      end

      def show = render json: @payment, serializer: RentPaymentSerializer

      # POST /api/v1/rent_payments
      # Pré-génère les échéances mensuelles pour un bail (landlord seulement).
      def create
        lease = scoped_leases.find(params.require(:lease_id))
        months = params[:months].to_i.positive? ? params[:months].to_i : 12

        payments = RentPayment.generate_for_lease(lease: lease, months: months)
        render json: payments, each_serializer: RentPaymentSerializer, status: :created
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      end

      # PATCH /api/v1/rent_payments/:id/mark_paid
      def mark_paid
        return forbidden unless landlord_owner?(@payment)

        method = params[:payment_method].presence
        @payment.mark_as_paid!(method: method)
        enqueue_receipt(@payment)
        render json: @payment, serializer: RentPaymentSerializer
      end

      private

      def enqueue_receipt(payment)
        period = payment.due_date.beginning_of_month
        pdf_bytes = ClarkAgent::ReceiptPdf.new(lease: payment.lease, period: period).render.read
        SendNotificationJob.perform_later(
          channel: 'email',
          recipient: payment.tenant.email,
          payload: {
            mailer: 'ReceiptMailer',
            action: 'delivered',
            args: {
              lease_id: payment.lease_id,
              period: period.to_s,
              pdf_bytes: Base64.strict_encode64(pdf_bytes)
            }
          }
        )
      end

      def set_payment
        @payment = scoped_payments.find(params[:id])
      end

      def scoped_payments
        if current_user.role == 'landlord'
          RentPayment.joins(lease: { room: :property })
                     .where(properties: { user_id: current_user.id })
        else
          RentPayment.where(tenant: current_user)
        end
      end

      def scoped_leases
        Lease.joins(room: :property).where(properties: { user_id: current_user.id })
      end

      def landlord_owner?(payment)
        current_user.role == 'landlord' &&
          payment.lease.room.property.user_id == current_user.id
      end

      def forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
