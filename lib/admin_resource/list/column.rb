module AdminResource
  module List
    class Column
      attr_accessor :attribute, :linked, :helper, :position, :list
      attr_writer :header
    
      def initialize(attribute, list, attributes={})
        @attribute = attribute
        @list      = list
        @position  = @list.columns.size

        @header    = attributes[:header]
        @helper    = attributes[:helper]
        @linked    = !!attributes[:linked] # force boolean
      end
    
      def header
        @header ||= @attribute.titleize 
      end
    
      def linked?
        linked
      end
    end
  end
end