/*
 * Copyright 2018 Google LLC
 * Copyright 2020 OpenHW Group
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//------------------------------------------------------------------------------
// CORE-V instruction generator configuration class:
//     - extension of the RISC-V instruction generator base test.
//
// The base test Uses the factory to replace riscv_instr_gen_config with corev_instr_gen_config
//------------------------------------------------------------------------------

class corev_instr_gen_config extends riscv_instr_gen_config;

  // External config control (plusarg) to enable/disable fast_interrupt handlers
  bit enable_fast_interrupt_handler;

  // Knob to set zero fast interrupt handler
  // Knob is needed because FIXED MTVEC mode won't work with fast interrupt handlers
  rand bit knob_zero_fast_intr_handlers;

  // Mask for using a fast interrupt handler (mret only), relying on h/W interrupt ack mechanism
  rand bit [31:0] use_fast_intr_handler;

  // CV32E40P requires the MTVEC table to be aligned to 256KB boundaries
  constraint mtvec_c {
    tvec_alignment == 8;
  }

  // Constrain fast interrupt handler
  constraint knob_zero_fast_intr_dist_c {
    solve knob_zero_fast_intr_handlers before use_fast_intr_handler;
    knob_zero_fast_intr_handlers dist {
                                        0 :/ 8,
                                        1 :/ 2
                                      };
  }

  constraint fast_intr_handler_c {
    if (!enable_fast_interrupt_handler) {
      knob_zero_fast_intr_handlers == 1;
    }
    
    // Nver use fast handler for exceptions (interrupt 0)
    use_fast_intr_handler[0] == 0;

    knob_zero_fast_intr_handlers -> !use_fast_intr_handler;    

    // VECTORED mode required for any fast interrupts
    if (use_fast_intr_handler) {
      mtvec_mode == VECTORED;
    }
  }

  `uvm_object_utils_begin(corev_instr_gen_config)
    `uvm_field_enum(mtvec_mode_t, mtvec_mode, UVM_DEFAULT)
    `uvm_field_int(knob_zero_fast_intr_handlers, UVM_DEFAULT)
    `uvm_field_int(enable_fast_interrupt_handler, UVM_DEFAULT)
    `uvm_field_int(use_fast_intr_handler, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="");
    super.new(name);

    get_bool_arg_value("+enable_fast_interrupt_handler=", enable_fast_interrupt_handler);
  endfunction

endclass
