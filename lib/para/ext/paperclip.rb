module Para
  module Ext
    module Paperclip
      module HasAttachedFileMixin
        extend ActiveSupport::Concern

        included do
          alias_method_chain :define, :removeable_management
        end

        def define_with_removeable_management
          define_without_removeable_management
          define_removeable
        end

        private

        def define_removeable
          return if @options[:removeable] == false

          attachment_name = @name
          klass = @klass
          # Define the setter to remove the attachment
          #
          @klass.send :define_method, :"remove_#{ attachment_name }=" do |value|
            if value == '1'
              removed_attachments << attachment_name

              # Notify ActiveRecord that the model has changed so nested models
              # get to run validation hooks and attachments are cleared
              column_name = attribute_container_column_for(attachment_name)
              send(:"#{ column_name }_will_change!")
            end
          end

          @klass.send :define_method, :"remove_#{ attachment_name }" do |value|
            removed_attachments.include?(attachment_name) ? '1' : nil
          end

          # Lazy method initialization on attachment target class
          #
          unless @klass.method_defined?(:removed_attachments)
            # List of all removed attachments for the current instance
            #
            @klass.send :define_method, :removed_attachments do
              @removed_attachments ||= []
            end

            # Define before validation hook to clear removed attachments before
            # the instance is validated
            #
            @klass.send :define_method, :clear_removed_attachments do
              removed_attachments.each do |name|
                if send(:"#{ name }?")
                  send(name).clear
                end
              end

              removed_attachments.clear
            end

            @klass.send(:before_validation, :clear_removed_attachments)
          end

          @klass.send(:define_method, :attribute_container_column_for) do |attachment_name|
            attribute_name = "#{ attachment_name }_file_name"

            if self.class.columns.any? { |column| column.name == attribute_name }
              return attribute_name
            end

            stored_attribute = self.class.stored_attributes.each do |key, fields|
              return key if fields.include?(attribute_name.to_sym)
            end
          end
        end
      end
    end
  end
end

require 'paperclip/media_type_spoof_detector'

module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
