/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
*/



`include "RV2T_common.vh"

`default_nettype none

module RV2T_machine_timer (

    //=======================================================================
    // clock / reset
    //=======================================================================
        input   wire                                            clk,
        input   wire                                            reset_n,
        input   wire                                            sync_reset,

    //=======================================================================
    //  control 
    //=======================================================================
        input wire                                              load_mtimecmp_low,
        input wire                                              load_mtimecmp_high,
        input wire [`XLEN - 1 : 0]                              mtimecmp_write_data,
        
        output reg                                              timer_triggered,
        
        input  wire [1 : 0]                                     reg_read_addr,
        output reg [`XLEN - 1 : 0]                              reg_read_data 

);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg   [`MTIME_CYCLE_PERIOD_BITS - 1 : 0]                mtime_cycle_counter;
        reg                                                     mtime_cycle_pulse;
        
        reg   [`XLEN * 2 - 1 : 0]                               mtime;
        reg   [`XLEN * 2 - 1 : 0]                               mtimecmp;
        
        reg   [`XLEN - 1 : 0]                                   mtime_high; 
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtime_cycle_counter
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                mtime_cycle_counter <= 0;
                mtime_cycle_pulse <= 0;
   
            end else if (mtime_cycle_counter != ((`MTIME_CYCLE_PERIOD_BITS)'(`MTIME_CYCLE_PERIOD - 1))) begin
                mtime_cycle_counter <= mtime_cycle_counter + 1;
                mtime_cycle_pulse <= 0;
            end else begin
                mtime_cycle_counter <= 0;
                mtime_cycle_pulse   <= 1'b1; 
            end
        end
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtime
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       
        always @(posedge clk, negedge reset_n) begin : mtime_proc
            if (!reset_n) begin
                mtime <= 0;
            end else if (mtime_cycle_pulse) begin
                mtime <= mtime + 1;
            end
        end
        
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtimecmp
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       
        always @(posedge clk, negedge reset_n) begin : mtimecmp_proc
            if (!reset_n) begin
                mtimecmp <= 0;
            end else if (load_mtimecmp_low) begin
                mtimecmp [`XLEN - 1 : 0] <= mtimecmp_write_data;
            end else if (load_mtimecmp_high) begin
                mtimecmp [`XLEN * 2 - 1 : `XLEN] <= mtimecmp_write_data;
            end
        end 
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // timer trigger
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : timer_triggered_proc
            if (!reset_n) begin
                timer_triggered <= 0;
            end else if (load_mtimecmp_low | load_mtimecmp_high) begin
                timer_triggered <= 0;
            end else if (mtime >= mtimecmp) begin
                timer_triggered <= 1'b1;
            end
        end
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                reg_read_data <= 0;
                mtime_high <= 0;
            end else begin
                case (reg_read_addr) 
                    2'b01 : begin
                        reg_read_data <= mtime_high;
                    end
                    
                    2'b10 : begin
                        reg_read_data <= mtimecmp [`XLEN - 1 : 0];
                    end
                
                    2'b11 : begin
                        reg_read_data <= mtimecmp [`XLEN * 2 - 1 : `XLEN];
                    end
                    
                    default : begin
                        reg_read_data <= mtime [`XLEN - 1 : 0];
                        mtime_high <= mtime [`XLEN * 2 - 1 : `XLEN];
                    end
                
                endcase

            end
        end

endmodule

`default_nettype wire
