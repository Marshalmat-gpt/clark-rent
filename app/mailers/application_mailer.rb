class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAIL_FROM', 'Clark Rent <noreply@clarkrent.com>')
  layout 'mailer'
end
