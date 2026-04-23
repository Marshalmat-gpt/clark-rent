require_relative 'application'

begin
  Rails.application.initialize!
rescue => e
  # Emit a GitHub Actions annotation so the real error appears in check-run
  # annotations even though we cannot access the raw job logs (403).
  lines = ["#{e.class}: #{e.message.split("\n").first(5).join(' | ')}",
           e.backtrace&.first(3)&.join(' | ')].compact.join(' -- BACKTRACE: ')
  $stderr.puts "::error::BOOT FAILURE: #{lines}"
  raise
end
