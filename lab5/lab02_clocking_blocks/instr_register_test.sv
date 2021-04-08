/***********************************************************************
 * A SystemVerilog testbench for an instructio.cbn register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generatio.cbn, functio.cbnal coverage, and
 * a scoreboard for self-verificatio.cbn.
 *
 * SystemVerilog Training Workshop.
 * Copyright 2006, 2013 by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.  All rights reserved.
 * www.sutherland-hdl.com
 **********************************************************************/

module instr_register_test (tb_ifc io);  // interface port

  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  int seed = 555;
  
  class transaction;
  
  rand opcode_t    opcode;
  rand  operand_t  operand_a, operand_b;
  rand    operand_t  write_pointer, read_pointer;
  
    constraint opcode_const
    {
          opcode >=0;
          opcode<=7;
          
    } 

    constraint operandA_const
    {
      operand_a >=-15;
      operand_a <=15;

    }

    constraint operandB_const
    {
      operand_b >=0;
      operand_b <=15;

    }

  /*function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;
    operand_a     = $random(seed)%16;                 // between -15 and 15
    operand_b     = $unsigned($random)%16;            // between 0 and 15
    opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    write_pointer = temp++;
  endfunction: randomize_transaction*/
  
  

  function void print_transaction;
    $display("Writing to register location %0d: ", io.write_pointer);
    $display("  opcode = %0d (%s)", io.opcode, io.opcode.name);
    $display("  operand_a = %0d",   io.operand_a);
    $display("  operand_b = %0d\n", io.operand_b);
  endfunction: print_transaction
  
   




endclass : transaction
  
class transaction_ext extends transaction;

  virtual function void print_tr();
    $display("sunt extinsaaaaa");
    super.print_transaction();
  endfunction : print_tr

endclass : transaction_ext


  class Driver;
    virtual tb_ifc vifc;
    transaction tr;
    transaction_ext tr_ext;


  
  function new (virtual tb_ifc vifc);
  this.vifc=vifc;
  tr=new();
  tr_ext=new();
  endfunction
  
  task generate_tr;
  
   $display("\n\n***********************************************************");
    $display(    "*  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  *");
    $display(    "*  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     *");
    $display(    "*  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  *");
    $display(    "*******************************************************");

    $display("\nReseting the instruction register...");
    vifc.cb.write_pointer <= 5'h00;      // initialize write pointer
    vifc.cb.read_pointer  <= 5'h1F;      // initialize read pointer
    vifc.cb.load_en       <= 1'b0;       // initialize load control line
    vifc.cb.reset_n       <= 1'b0;       // assert reset_n (active low)
    repeat (2) @( io.cb) ;  // hold in reset for 2 clock cycles
    vifc.reset_n       = 1'b1;       // assert reset_n (active low)

    $display("\nWriting values to register stack...");
    @( io.cb) io.load_en = 1'b1;  // enable writing to register
    repeat (3) begin
      @( vifc.cb) tr.randomize;
	  vifc.cb.operand_a <= tr.operand_a;
	  vifc.cb.operand_b <= tr.operand_b;
	  vifc.cb.opcode 	<= tr.opcode;
	  vifc.cb.write_pointer<= tr.write_pointer;
      @( vifc.cb) tr.print_transaction;
    end
    @(vifc.cb) vifc.load_en = 1'b0;  // turn-off writing to register
	
	endtask

    task reset_signals;

         
          io.write_pointer = 5'h00;      // initialize write pointer
          io.read_pointer  = 5'h1F;      // initialize read pointer
          io.load_en       = 1'b0;       // initialize load control line
          io.reset_n       = 1'b0;       // assert reset_n (active low)

    endtask

    task assign_signals;

                $display("\nWriting values to register stack...");
                @( io.cb) io.load_en = 1'b1;  // enable writing to register
                repeat (3) begin
                @( vifc.cb) tr.randomize;
	              vifc.cb.operand_a <= tr.operand_a;
	              vifc.cb.operand_b <= tr.operand_b;
	              vifc.cb.opcode 	<= tr.opcode;
	              vifc.cb.write_pointer<= tr.write_pointer;
                @( vifc.cb) tr.print_transaction;
                end
                @(vifc.cb) vifc.load_en = 1'b0;  // turn-off writing to register


    endtask

	endclass : Driver
	
	
	class Monitor;
	virtual tb_ifc vifc;
	function new (virtual tb_ifc vifc);
		this.vifc <= vifc;
	endfunction
	
	task read_results;
	
	 // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<=2; i++) begin
      // A later lab will replace this loop with iterating through a
      // scoreboard to determine which address were written and the
      // expected values to be read back
      @(io.cb) io.read_pointer = i;
      @( io.cb) print_results;
    end

    @( vifc.clk) ;
    $display("\n***********************************************************");
    $display(  "*  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  *");
    $display(  "*  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     *");
    $display(  "*  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  *");
    $display(  "***********************************************************\n");
    $finish;
  endtask
  
  task print_results;
    $display("Read from register location %0d: ", vifc.read_pointer);
    $display("  opcode = %0d (%s)", vifc.cb.instruction_word.opc, vifc.cb.instruction_word.opc.name);
    $display("  operand_a = %0d",   vifc.cb.instruction_word.op_a);
    $display("  operand_b = %0d\n", vifc.cb.instruction_word.op_b);
  endtask
  endclass : Monitor
  

  initial begin
  
  Driver dr;
  Monitor mn;
  
  dr=new(.vifc(io));
  mn=new(.vifc(io));


  dr.reset_signals;
  dr.assign_signals;

  
  $finish;
  end
  
  
   /* $display("\n\n***********************************************************");
    $display(    "*  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  *");
    $display(    "*  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     *");
    $display(    "*  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  *");
    $display(    "*******************************************************");

    $display("\nReseting the instruction register...");
    io.write_pointer = 5'h00;      // initialize write pointer
    io.read_pointer  = 5'h1F;      // initialize read pointer
    io.load_en       = 1'b0;       // initialize load control line
    io.reset_n       = 1'b0;       // assert reset_n (active low)
    repeat (2) @(posedge io.cb) ;  // hold in reset for 2 clock cycles
    io.reset_n       = 1'b1;       // assert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge io.cb) io.load_en = 1'b1;  // enable writing to register
    repeat (3) begin
      @(posedge io.cb) randomize_transaction;
      @(negedge io.cb) print_transaction;
    end
    @(posedge io.cb) io.load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<=2; i++) begin
      // A later lab will replace this loop with iterating through a
      // scoreboard to determine which address were written and the
      // expected values to be read back
      @(posedge io.cb) io.read_pointer = i;
      @(posedge io.cb) print_results;
    end

    @(posedge io.clk) ;
    $display("\n***********************************************************");
    $display(  "*  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  *");
    $display(  "*  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     *");
    $display(  "*  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  *");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;
    io.operand_a     = $random(seed)%16;                 // between -15 and 15
    io.operand_b     = $unsigned($random)%16;            // between 0 and 15
    io.opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    io.write_pointer = temp++;
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", io.write_pointer);
    $display("  opcode = %0d (%s)", io.opcode, io.opcode.name);
    $display("  operand_a = %0d",   io.operand_a);
    $display("  operand_b = %0d\n", io.operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", io.read_pointer);
    $display("  opcode = %0d (%s)", io.cb.instruction_word.opc, io.cb.instruction_word.opc.name);
    $display("  operand_a = %0d",   io.cb.instruction_word.op_a);
    $display("  operand_b = %0d\n", io.cb.instruction_word.op_b);
  endfunction: print_results*/
endmodule: instr_register_test