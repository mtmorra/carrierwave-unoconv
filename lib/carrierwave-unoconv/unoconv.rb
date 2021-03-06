module CarrierWave
  module UNOConv
    extend ActiveSupport::Concern
    module ClassMethods
      def uno_convert format
        process uno_convert: format
      end
    end

    def uno_convert format
      directory = File.dirname( current_path )
      tmpfile   = File.join( directory, "tmpfile" )

      File.rename( current_path, tmpfile )
      begin
        Rails.logger.debug("BEGIN CONVERT!!!")
        Timeout.timeout(300) do
          @pid = Process.spawn("unoconv -f #{format} #{tmpfile}")
          Rails.logger.debug("Conversion Started!!!")
          Rails.logger.debug("PID IS #{@pid}")
          Process.wait(@pid)
          Rails.logger.debug("Conversion Finished!!!")
        end
          #system "unoconv -f #{format} '#{tmpfile}'"
          File.rename( File.join(directory, "tmpfile.#{format}"), current_path )
          File.delete( tmpfile )
          if model.respond_to?('pdf_encoding_state')
            model.pdf_encoding_state = 1
          end
      rescue Timeout::Error
        Rails.logger.debug("TIMEOUT OCCURRED!")
        system "kill #{@pid.to_i}"
        Rails.logger.debug("KILLED PROCESS #{@pid.to_i}")
        if model.respond_to?('pdf_encoding_state')
          model.pdf_encoding_state = 2
        end
      rescue Exception=>e
        if model.respond_to?('pdf_encoding_state')
          model.pdf_encoding_state = 2
        end
        Rails.logger.error("Error converting file #{current_path} #{e}")
      end
    end
  end
end