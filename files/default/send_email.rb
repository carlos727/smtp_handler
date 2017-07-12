require 'net/smtp'

module Email
  class SendEmail < Chef::Handler
    def report
      message = "Chef run failed at #{Time.now.iso8601}, check the attached log.\n"
      message << "#{run_status.formatted_exception}\n"
      message << Array(backtrace).join("\n")

      if failed?
        send_email :message => message
      end
    end

    def send_email opts={}
      opts[:server]      ||= 'smtp.office365.com'
      opts[:port]        ||= 587
      opts[:from]        ||= 'barcoder@redsis.com'
      opts[:password]    ||= 'Orion2015'
      opts[:from_alias]  ||= 'Chef Reporter'
      opts[:to]          ||= ['cbeleno@redsis.com']
      opts[:subject]     ||= "Chef Failed on Node #{Chef.run_context.node.name}"
      opts[:message]     ||= "..."

      filename = "C:\\chef\\log-#{Chef.run_context.node.name}"
      # Read a file and encode it into base64 format
      encodedcontent = [File.read(filename)].pack("m")   # base64

      marker = "AUNIQUEMARKER"

      # Define the main headers.
      header = <<-HEADER
        From: #{opts[:from_alias]} <#{opts[:from]}>
        To: <#{opts[:to] }>
        Subject: #{opts[:subject]}
        MIME-Version: 1.0
        Content-Type: multipart/mixed; boundary=#{marker}
        --#{marker}
      HEADER

      # Define the message action
      body = <<-BODY
        Content-Type: text/plain
        Content-Transfer-Encoding:8bit

        #{opts[:message]}
        --#{marker}
      BODY

      # Define the attachment section
      attached = <<-ATTACHED
        Content-Type: multipart/mixed; name=\"#{filename}\"
        Content-Transfer-Encoding:base64
        Content-Disposition: attachment; filename="#{filename}"

        #{encodedcontent}
        --#{marker}--
      ATTACHED

      mailtext = unindent header + body + attached

      smtp = Net::SMTP.new(opts[:server], opts[:port])
      smtp.enable_starttls_auto
      smtp.start(opts[:server], opts[:from], opts[:password], :login)
      smtp.send_message(mailtext, opts[:from], opts[:to])
      smtp.finish
    end

    def unindent string
      first = string[/\A\s*/]
      string.gsub /^#{first}/, ''
    end
  end
end
