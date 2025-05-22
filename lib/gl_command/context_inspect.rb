# frozen_string_literal: true

module GLCommand
  class ContextInspect
    PERMITTED_OUTPUTS = %i[string hash].freeze

    class << self
      def error(error_obj)
        return '' if error_obj.blank?

        error_obj.is_a?(Array) ? error_obj.uniq.join(', ') : error_obj.to_s
      end

      def hash_params(hash, output: :string)
        unless PERMITTED_OUTPUTS.include?(output)
          raise "Unknown output type: #{output}, must be one of #{PERMITTED_OUTPUTS}"
        end

        result = hash.map { |key, value| output_for(key:, value:, output:) }
        output == :string ? result.join(', ') : result.to_h
      end

      private

      def output_for(key:, value:, output:)
        value_s = if value.nil?
                    'nil'
                  elsif value.respond_to?(:to_sql)
                    object_param_as_sql(value, output:)
                  elsif value.respond_to?(:id)
                    object_param_with_id(value, :id, output:)
                  elsif value.respond_to?(:uuid)
                    object_param_with_id(value, :uuid, output:)
                  else
                    value
                  end

        output == :string ? "#{key}: #{value_s}" : [key, value_s]
      end

      # Active record objects can be really big - rather than rendering the whole object, just show the ID
      def object_param_with_id(obj, key, output:)
        obj_id = obj.send(key)
        if output == :string
          id_value = obj_id.is_a?(Integer) ? obj_id : "\"#{obj_id}\""
          "#<#{obj.class.name} #{key}=#{id_value}>"
        else
          obj_id
        end
      end

      def object_param_as_sql(obj, output:)
        if output == :string
          "#<#{obj.class.name} sql=\"#{obj.to_sql}\">"
        else
          obj.to_sql
        end
      end
    end
  end
end
