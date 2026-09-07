class ApplicationMailer < ActionMailer::Base
  default from: "Handoff <no-reply@handoff.delivery>"
  layout "mailer"
end
