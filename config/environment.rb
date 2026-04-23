require_relative 'application'

begin
  Rails.application.initialize!
rescue => e
  lines = ["#{e.class}: #{e.message.split("\n").first(5).join(' | ')}",
           e.backtrace&.first(3)&.join(' | ')].compact.join(' -- BACKTRACE: ')
  $stderr.puts "::error::BOOT FAILURE: #{lines}"
  raise
end
