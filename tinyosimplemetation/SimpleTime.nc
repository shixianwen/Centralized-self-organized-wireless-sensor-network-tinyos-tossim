/* 
-----------------------------------------------------------------------
--                               ITEM                                --
--                Integrated TDMA E-ASAP Module (ITEM)               --
--                                                                   --
--                     Copyright (C) 2007                            --
-- Department of Control Engineering FEE CTU Prague, Czech Republic  --
--                     http://dce.felk.cvut.cz                       --
--                                                                   --
-- Author: 	Pavel Benes	<benesp5@fel.cvut.cz>                --
-- Advisor: 	Jiri Trdlicka	<trdlij1@gmail.com>                  --
--                                                                   --
-- version: 2.0    24.6.2008                                         --
-----------------------------------------------------------------------

This file is part of ITEM project.

    ITEM is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ITEM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
    
*/


/**
 * SimpleTime Interface
 *
 * Time manipulations and calculations.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/

//includes SimpleTime;
#include "SimpleTime.h"

interface SimpleTime
{

  /** 
   * Add a unsigned 32 bits integer to a logical time   
   *  
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit 
   *           should be binary milliseconds
   * @return   The new time in tos_time_t format.
   **/
  async command tos_time_t addUint32(tos_time_t a ,uint32_t x);
  
  /**
   * Add a signed 32 bits integer to a logical time
   *
   * @param a  Logical Time
   *
   * @Param x  A 32 bit integer. If it represent a time, the unit
   *           should be binary milliseconds
   * @return   The new time in tos_time_t format.
   **/
  async command tos_time_t addint32(tos_time_t a ,int32_t x);
  
  /**
   *  Compare logical time a and b
   *
   *  @param a  logical time
   *
   *  @param b  logical time
   *
   *  @return 1 if a>b
   *	      0 if a==b
   *	     -1 if a<b
   **/
  async command char compare(tos_time_t a ,tos_time_t b);
  
  /**
   *  Subtract logical time b from a
   *
   *  @param a  logical time
   *
   *  @param b  logical time
   *
   *  @return the time difference
   **/
   async command tos_time_t subtract(tos_time_t a, tos_time_t b);
   
  /**
   * Subtract a unsigned 32 bits integer from a logical time
   *
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit
   *           should be binary milliseconds
   * @return   The result in tos_time_t format.
   **/
  async command tos_time_t subtractUint32(tos_time_t a, uint32_t x);
  
  /** 
   * Create a logical time from two unsigned 32 bits integer
   *
   * @param timeH represent the high 32 bits of a logical time
   *
   * @param timeL low 32 bits of a logical time
   *
   * @return The created logical time
   **/ 
  async command tos_time_t create(uint32_t timeH, uint32_t timeL);

  /**
   * Adjust logical time by n  binary milliseconds.
   *
   * @param us unsigned 16 bit interger 
   * 	positive number advances the logical time 
   *    negtive argument regress the time 
   *    This operation will not take effect immidiately
   *    The adjustment is done during next clock.fire event
   *    handling.
   * @return none
   **/
  command void adjust(int16_t n);
  
  /**
   * Adjust logical time by x milliseconds.
   *
   * @param x  32 bit interger
   * 	positive number advances the logical time
   *    negtive argument regress the time
   * @return none
   **/
  command void adjustNow(int32_t x); 

  /**
   * Set the 32 bits logical time to a specified value 
   * @param t Time in the unit of binary milliseconds
   * 	type is tos_time_t
   * @return none
   **/
  command void set(tos_time_t t);  
  
  /**
   * Get current time. Return it in tos_time_t structure 
   **/
  async command tos_time_t get();
  
  //½«tdmastattime ÉèÖÃºÃ
  command void set_tdmastarttime(tos_time_t t); 
  event void sigtdmatimecoming();

 }
