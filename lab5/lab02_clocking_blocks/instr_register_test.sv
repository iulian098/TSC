/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/
import instr_register_pkg::*;

module instr_register_test (tb_ifc intf); 

  timeunit 1ns/1ns;

  int seed = 555;

	class transaction;

		rand opcode_t       opcode;
		rand operand_t		operand_a, operand_b;
		address_t      write_pointer;
		
    constraint const_op_a{
      operand_a >= -15;
      operand_a <= 15;
    }

    constraint const_op_b{
      operand_b >= 0;
      operand_b <= 15;
    }

    constraint const_opcode{
      opcode >= 0;
      opcode <= 7;
    }

		// function void randomize_transaction;
		// 	// A later lab will replace this function with SystemVerilog
		// 	// constrained random values
		// 	//
		// 	// The stactic temp variable is required in order to write to fixed
		// 	// addresses of 0, 1 and 2.  This will be replaceed with randomizeed
		// 	// write_pointer values in a later lab
		// 	//
		// 	static int temp = 0;
		// 	operand_a     = $random(seed)%16;                 // between -15 and 15
		// 	operand_b     = $unsigned($random)%16;            // between 0 and 15
		// 	opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
		// 	write_pointer = temp++;
		// endfunction: randomize_transaction
		
		function void print_transaction;
			$display("Writing to register location %0d: ", write_pointer);
			$display("  opcode = %0d (%s)", opcode, opcode.name);
			$display("  operand_a = %0d",   operand_a);
			$display("  operand_b = %0d\n", operand_b);
		endfunction: print_transaction

    
	endclass : transaction


	class driver;
	
    transaction tr;
    virtual tb_ifc vifc;

    function new(virtual tb_ifc vifc);
      tr = new();
      this.vifc = vifc;
    endfunction

    task reset_sig;

      vifc.cb.write_pointer <= 5'h00;
      vifc.cb.read_pointer   <= 5'h1F;         // initialize read pointer
      vifc.cb.load_en        <= 1'b0;          // initialize load control line
      vifc.cb.reset_n       <= 1'b0;          // assert reset_n (active low)
      repeat (2) @vifc.cb ;     // hold in reset for 2 clock cycles
      vifc.cb.reset_n        <= 1'b1;          // deassert reset_n (active low)

    endtask

    function assign_sig;

        static int temp = 0;
        tr.write_pointer = temp++;
        vifc.cb.write_pointer  <= tr.write_pointer;
        vifc.cb.operand_a <= tr.operand_a;
        vifc.cb.operand_b <= tr.operand_b;
        vifc.cb.opcode <= tr.opcode;

    endfunction

    task generate_transaction; 

      $display("\nReseting the instruction register...");
      
      reset_sig;
      // vifc.cb.write_pointer <= 5'h00;
      // vifc.cb.read_pointer   <= 5'h1F;         // initialize read pointer
      // vifc.cb.load_en        <= 1'b0;          // initialize load control line
      // vifc.cb.reset_n       <= 1'b0;          // assert reset_n (active low)
      // repeat (2) @vifc.cb ;     // hold in reset for 2 clock cycles
      // vifc.cb.reset_n        <= 1'b1;          // deassert reset_n (active low)

      @vifc.cb vifc.cb.load_en <= 1'b1;
      repeat(3) begin

        tr.randomize;//tr.randomize_transaction;

        assign_sig;

        // vifc.cb.write_pointer  <= tr.write_pointer;
        // vifc.cb.operand_a <= tr.operand_a;
        // vifc.cb.operand_b <= tr.operand_b;
        // vifc.cb.opcode <= tr.opcode;

        @vifc.cb tr.print_transaction;

      end
      @vifc.cb vifc.cb.load_en <= 1'b0;
    endtask
	endclass : driver

  class monitor;

    virtual tb_ifc vifc;
    function new(virtual tb_ifc vifc);
      this.vifc = vifc;
    endfunction

    function void print_results;
    $display("Read from register location %0d: ", vifc.cb.read_pointer);
    $display("  opcode = %0d (%s)", vifc.cb.instruction_word.opc, vifc.cb.instruction_word.opc.name);
    $display("  operand_a = %0d",   vifc.cb.instruction_word.op_a);
    $display("  operand_b = %0d\n", vifc.cb.instruction_word.op_b);
    endfunction: print_results

    task read_transaction;
      $display("\nReading back the same register locations written...");
      for (int i=0; i<=2; i++) begin
        // later labs will replace this loop with iterating through a
        // scoreboard to determine which addresses were written and
        // the expected values to be read back
        @vifc.cb vifc.cb.read_pointer <= i;
        @vifc.cb print_results;
      end
    endtask

  endclass

  initial begin
    driver dr;
    monitor mot;
    dr = new(intf);
    mot = new(intf);

    dr.generate_transaction;
    mot.read_transaction;
    $finish;
  end
  // initial begin
  //   $display("\n\n***********************************************************");
  //   $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
  //   $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
  //   $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
  //   $display(    "***********************************************************");

  //   $display("\nReseting the instruction register...");
  //   intf.cb.write_pointer  <= 5'h00;         // initialize write pointer
  //   intf.cb.read_pointer   <= 5'h1F;         // initialize read pointer
  //   intf.cb.load_en        <= 1'b0;          // initialize load control line
  //   intf.cb.reset_n       <= 1'b0;          // assert reset_n (active low)
  //   repeat (2) @intf.cb ;     // hold in reset for 2 clock cycles
  //   intf.cb.reset_n        <= 1'b1;          // deassert reset_n (active low)

  //   $display("\nWriting values to register stack...");
  //   @intf.cb intf.cb.load_en <= 1'b1;  // enable writing to register
  //   repeat (3) begin
  //     @intf.cb randomize_transaction;
  //     @intf.cb print_transaction;
  //   end
  //   @intf.cb intf.cb.load_en <= 1'b0;  // turn-off writing to register

  //   // read back and display same three register locations
  //   $display("\nReading back the same register locations written...");
  //   for (int i=0; i<=2; i++) begin
  //     // later labs will replace this loop with iterating through a
  //     // scoreboard to determine which addresses were written and
  //     // the expected values to be read back
  //     @intf.cb intf.cb.read_pointer <= i;
  //     @intf.cb print_results;
  //   end

  //   @intf.cb ;
  //   $display("\n***********************************************************");
  //   $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
  //   $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
  //   $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
  //   $display(  "***********************************************************\n");
  //   $finish;
  // end

  // function void randomize_transaction;
  //   // A later lab will replace this function with SystemVerilog
  //   // constrained random values
  //   //
  //   // The stactic temp variable is required in order to write to fixed
  //   // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
  //   // write_pointer values in a later lab
  //   //
  //   static int temp = 0;
  //   intf.cb.operand_a     <= $random(seed)%16;                 // between -15 and 15
  //   intf.cb.operand_b     <= $unsigned($random)%16;            // between 0 and 15
  //   intf.cb.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
  //   intf.cb.write_pointer <= temp++;
  // endfunction: randomize_transaction

  // function void print_transaction;
  //   $display("Writing to register location %0d: ", intf.cb.write_pointer);
  //   $display("  opcode = %0d (%s)", intf.cb.opcode, intf.cb.opcode.name);
  //   $display("  operand_a = %0d",   intf.cb.operand_a);
  //   $display("  operand_b = %0d\n", intf.cb.operand_b);
  // endfunction: print_transaction

  // function void print_results;
  //   $display("Read from register location %0d: ", intf.cb.read_pointer);
  //   $display("  opcode = %0d (%s)", intf.cb.instruction_word.opc, intf.cb.instruction_word.opc.name);
  //   $display("  operand_a = %0d",   intf.cb.instruction_word.op_a);
  //   $display("  operand_b = %0d\n", intf.cb.instruction_word.op_b);
  // endfunction: print_results

endmodule: instr_register_test
