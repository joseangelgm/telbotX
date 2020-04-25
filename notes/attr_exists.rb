class Test

    attr_reader :var

    def initialize
        @var = "prr"
    end
end

aux = Test.new

if aux.instance_variable_defined?(:@var)
    puts "Has the attribute and the value is #{aux.var}"
else
    puts "No attribute"
end