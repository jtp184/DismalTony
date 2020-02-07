module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
    # Provides simpler access to DataStore#directive_data, and streamlines
    # defining and creating structs to put in it.
    module DataStructHelpers
      include HelperTemplate

      # Provides simpler access to DataStore#directive_data, and streamlines
      # defining and creating structs to put in it.
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Takes in a block returning a Struct, where user schema is defined.
        def define_data_struct
          @data_struct_template = yield
        end

        # Gets data_struct_template
        def data_struct_template
          @data_struct_template
        end

        # Sets data_struct_template
        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end

      # Provides simpler access to DataStore#directive_data, and streamlines
      # defining and creating structs to put in it.
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Uses the Directive's name, and any passed values to dig into the directive data
        def get_stored_data(*ky)
          vi.data_store.read_data(name, *ky)
        end

        # In this Directive's storage, stores +ky+ with a value of +v+.
        # If a block is given, passes it to #data_struct and uses that as the value.
        def store_data(ky, v = nil, &block)
          if block_given?
            vi.data_store.store_data(directive: name, key: ky, value: data_struct(&block))
          else
            vi.data_store.store_data(directive: name, key: ky, value: v)
          end
        end

        # Takes in arguments to create a new struct. If no #data_struct_template is defined,
        # It creates an OpenStruct instead. Otherwise, correctly maps values to the struct.
        def data_struct # :yields: arguments
          ud_args = {}
          yield ud_args
          if data_struct_template.nil?
            OpenStruct.new(ud_args)
          else
            args_list = data_struct_template.members.map { |a| ud_args[a] }
            data_struct_template.new(*args_list)
          end
        end

        # Instance hook for the data struct template
        def data_struct_template
          @data_struct_template ||= self.class.public_send(:data_struct_template)
          @data_struct_template
        end

        # Sets the data struct template
        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end
    end
  end
end
