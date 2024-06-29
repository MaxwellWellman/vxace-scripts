module MWCORE
  class_exec do

    Class.class_eval do

      def patch(method_name, &new_body)
        old_body = instance_method(method_name)
        class_exec do
          define_method method_name do |*args, &block|
            new_body.call_as(self, old_body.bind(self), *args, &block)
          end
        end
      end

    end

    Proc.class_eval do

      def call_as(caller, *args, &block)
        temp_name = "unbound"
        while caller.singleton_class.method_defined?(temp_name)
          temp_name.concat("_")
        end
        caller.define_singleton_method(temp_name, &self)
        unbound = caller.singleton_class.instance_method(temp_name)
        caller.singleton_class.send(:remove_method, temp_name)
        unbound.bind(caller)[*args, &block]
      end

    end

    IO.class_eval do

      patch(:puts) do |super_, first, *rest|
        super_[first.to_s, *rest]
      end

    end

    Object.class_eval do

      def invar(name)
        instance_variable_get(name)
      end

      def invar!(name, val)
        instance_variable_set(name, val)
      end

      def call_method_as(target, method_name, *args, &block)
        unbound = target.instance_method(method_name)
        unbound.bind(self)[*args, &block]
      end

      def audit(indent = 1)
        case self
        when Class, Integer, Float, TrueClass, FalseClass
          return to_s
        when NilClass
          return 'nil'
        when String
          return "\"#{self}\""
        when Symbol
          return ":#{self}"
        when Proc
          return self.class.to_s
        end
        str = "#{"\t" * (indent - 1)}#{self.class} \{"
        instance_variables.each do |invar_name|
          val = instance_variable_get(invar_name)
          val = if val.is_a?(Array) or val.is_a?(Hash)
                  val.audit(indent + 1)
                elsif indent >= 6
                  val.to_s
                else
                  val.audit(indent + 1)
                end
          str.concat("\n#{"\t" * indent}#{invar_name} = #{val}")
        end
        str.concat("\n#{"\t" * (indent - 1)}\}")
      end

    end

    Hash.class_eval do

      def audit(indent = 1)
        return '{}' if length.zero?

        s = '{'
        each_pair do |k, v|
          s.concat("\n#{"\t" * indent}#{
            k.is_a?(Symbol) ? ':' : "\""
          }#{k}#{
            k.is_a?(Symbol) ? '' : "\""
          } => #{
            v.audit(indent + 1)
          },")
        end
        s.concat("\n#{"\t" * (indent - 1)}}")
      end

    end

    Array.class_eval do

      def audit(indent = 1)
        return '[]' if length.zero?

        s = '['
        each do |e|
          s.concat(
            "\n#{"\t" * indent}#{
              e.audit(indent + 1)
            },"
          )
        end
        s.concat("\n#{"\t" * (indent - 1)}]")
      end

    end

    NilClass.class_eval do

      def to_s
        'nil'
      end

    end

    Integer.class_eval do

      def clamp(s, e)
        [s, self, e].sort[1]
      end

    end

  end
end
