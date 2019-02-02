module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
    # Provides a mechanism to return rich values from responses
    module DataRepresentationHelpers
      include HelperTemplate

      # Provides a mechanism to return rich values from responses
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Defines a default data representation
        def define_data_representation
          @data_representation = yield
        end

        # Gets data_representation
        def data_representation
          @data_representation
        end

        # Sets data_representation to +new_val+
        def data_representation=(new_val)
          @data_representation = new_val
        end
      end

      # Provides a mechanism to return rich values from responses
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Instance hook for data_representation
        def data_representation
          @data_representation ||= self.class.data_representation
          @data_representation ||= parameters
          @data_representation ||= OpenStruct.new
          @data_representation
        end

        # Sets data_representation to +new_val+
        def data_representation=(new_val)
          @data_representation = new_val
        end

        # DSL method, overwrites data representation
        def return_data(data)
          @data_representation = data
        end
      end
    end
  end
end
