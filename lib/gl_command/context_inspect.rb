module GLCommand
  class ContextInspect
    def self.error(error_obj)
      return '' if error_obj.blank?

      error_obj.is_a?(Array) ? error_obj.uniq.join(', ') : error_obj.to_s
    end

    def self.hash_params(hash)
      hash.map do |key, value|
        value_s =
          if value.nil?
            'nil'
          elsif value.respond_to?(:to_sql)
            object_param_as_sql(value)
          elsif value.respond_to?(:uuid)
            object_param_with_id(value, :uuid)
          elsif value.respond_to?(:id)
            object_param_with_id(value, :id)
          else
            value
          end
        "#{key}: #{value_s}"
      end.join(', ')
    end

    # Active record objects can be really big - rather than rendering the whole object, just show the ID
    private_class_method def self.object_param_with_id(obj, key)
      obj_id = obj.send(key)
      id_value = obj_id.is_a?(Integer) ? obj_id : "\"#{obj_id}\""
      "#<#{obj.class.name} #{key}=#{id_value}>"
    end

    private_class_method def self.object_param_as_sql(obj)
      count =
        if obj.respond_to?(:count)
          obj.count
        else
          'N/A'
        end
      "#<#{obj.class.name} count=#{count}, sql=\"#{obj.to_sql}\">"
    end
  end
end
