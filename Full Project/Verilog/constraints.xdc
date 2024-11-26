set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Create a clock constraint for a 100 MHz clock signal named 'clk'
create_clock -period 11.000 -name clk [get_ports clk]


