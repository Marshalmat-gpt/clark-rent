# Offset/limit pagination shared by every API V1 index endpoint.
#
# Reads `?page=` (default 1) and `?per_page=` (default 25, capped 100).
# Sets response headers:
#   X-Total-Count    total rows matching the scope
#   X-Page           current page
#   X-Per-Page       page size actually applied
#   X-Total-Pages    derived ceil(total / per_page)
#
# Usage in controllers:
#   def index
#     records = paginate(scoped_records.order(...))
#     render json: records, each_serializer: FooSerializer
#   end
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE     = 100

  private

  def paginate(scope)
    page     = pagination_page
    per_page = pagination_per_page
    apply_pagination_headers(scope, page, per_page)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def apply_pagination_headers(scope, page, per_page)
    total = scope.respond_to?(:size) ? scope.size : scope.count
    pages = total.zero? ? 0 : (total.to_f / per_page).ceil
    response.set_header('X-Total-Count', total.to_s)
    response.set_header('X-Page',        page.to_s)
    response.set_header('X-Per-Page',    per_page.to_s)
    response.set_header('X-Total-Pages', pages.to_s)
  end

  def pagination_page
    raw = params[:page].to_i
    raw.positive? ? raw : 1
  end

  def pagination_per_page
    raw = params[:per_page].to_i
    return DEFAULT_PER_PAGE if raw <= 0

    [raw, MAX_PER_PAGE].min
  end
end
