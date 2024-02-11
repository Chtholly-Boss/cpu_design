echo "Compiling..."
iverilog -y ./module -o wave testbench.v
echo "Compile Finished,Generating WaveFile..."
vvp -n wave -lxt2
copy wave.vcd wave.lxt
echo "Opening the WaveFile"
gtkwave wave.lxt
