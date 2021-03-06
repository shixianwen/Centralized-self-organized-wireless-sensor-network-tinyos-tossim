/* 
-----------------------------------------------------------------------
--                               ITEM                                --
--                Integrated TDMA E-ASAP Module (ITEM)               --
--                                                                   --
--                     Copyright (C) 2008                            --
-- Department of Control Engineering FEE CTU Prague, Czech Republic  --
--                     http://dce.felk.cvut.cz                       --
--                                                                   --
-- Author: 	Pavel Benes   	<benesp5@fel.cvut.cz>                --
-- Advisor: 	Jiri Trdlicka  	<trdlij1@gmail.com>                  --
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
 * SimpleTime Module
 *
 * Time manipulations and calculations.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/

//includes SimpleTime;
#include "SimpleTime.h"

module SimpleTimeC
{
  provides
  { 
  	interface SimpleTime;
  }

  uses
  {
  	interface Timer<TMilli> as Timer0;
 	interface Boot;

 	interface Leds;
  }
}

implementation
{
  enum {
  	INTERVAL =  1
  };
  tos_time_t time;  // logical time
  tos_time_t tdmastarttime = 0xffffffff;//判断tdma两个时刻是否相等，然后signal一个所有节点的起始TDMA的事件
  bool settdma = FALSE;
  /**
   * Initialize the component.
   * 
   * @return none
   **/
  event void Boot.booted()
  {
  	// initialize logical time
  	atomic {
		time = 0;
    	}
    	call Timer0.startPeriodic(INTERVAL);
  }
  
  /**
   * Event handler from the timer.
   **/  
  event void Timer0.fired()
  {
    	atomic time = call SimpleTime.addUint32(time, INTERVAL);
	if((time == tdmastarttime)&&settdma){
		//signal 所有节点tdma的时刻开始啦
		signal SimpleTime.sigtdmatimecoming();
		dbg("lab", "it's time to let tdma start !!!!\n");
	}
  }
  
  /**
   * Get current time. Return it in tos_time_t structure 
   **/  
  async command tos_time_t SimpleTime.get()
  {
  	tos_time_t t;

    	atomic t = time;
    	return t;
  }
  
  /**
   * Set the 32 bits logical time to a specified value 
   * @param t Time in the unit of binary milliseconds
   * 	type is tos_time_t
   * @return none
   **/
  command void SimpleTime.set(tos_time_t t)
  {
  	atomic {
  		time = t;
		
    	}
  }

  command void SimpleTime.set_tdmastarttime(tos_time_t t)
  {
  	atomic {
  		tdmastarttime = t;
		settdma = TRUE;
		dbg("lab","settdma %d",settdma);
    	}
  }
  
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
  command void SimpleTime.adjust(int16_t n)
  {
  	call SimpleTime.adjustNow(n);
  }

  /**
   * Adjust logical time by x milliseconds.
   *
   * @param x  32 bit interger
   * 	positive number advances the logical time
   *    negtive argument regress the time
   * @return none
   **/
  command void SimpleTime.adjustNow(int32_t x)
  {
  	call SimpleTime.set(call SimpleTime.addint32(time, x));
  }
  
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
  async command char SimpleTime.compare(tos_time_t a, tos_time_t b)
  {
    if (a > b ) return 1;
    if (a < b ) return -1;
    return 0;
  }
  
  /**
   *  Subtract logical time b from a
   *
   *  @param a  logical time
   *
   *  @param b  logical time
   *
   *  @return the time difference
   **/
  async command tos_time_t SimpleTime.subtract(tos_time_t a, tos_time_t b)
  {
   	return a - b; 
  }
  
  /**
   * Subtract a unsigned 32 bits integer from a logical time
   *
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit
   *           should be binary milliseconds
   * @return   The result in tos_time_t format.
   **/
  async command tos_time_t SimpleTime.subtractUint32(tos_time_t a, uint32_t ms)
  {
   	return a - ms;     	
  }
  
  /**
   * Add a signed 32 bits integer to a logical time
   *
   * @param a  Logical Time
   *
   * @Param x  A 32 bit integer. If it represent a time, the unit
   *           should be binary milliseconds
   * @return   The new time in tos_time_t format.
   **/
  async command tos_time_t SimpleTime.addint32(tos_time_t a, int32_t ms)
  {
	if (ms > 0)
		return call SimpleTime.addUint32(a, ms);
   	 else
      		// Note: ms == minint32 will still give the correct value
      		return call SimpleTime.subtractUint32(a, (uint32_t)-ms);
  }
  
  /** 
   * Add a unsigned 32 bits integer to a logical time   
   *  
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit 
   *           should be binary milliseconds
   * @return   The new time in tos_time_t format.
   **/
  async command tos_time_t SimpleTime.addUint32(tos_time_t a, uint32_t ms)
  {
	return a + ms;       	
  } 
  
  /** 
   * Create a logical time from two unsigned 32 bits integer
   *
   * @param timeH represent the high 32 bits of a logical time
   *
   * @param timeL low 32 bits of a logical time
   *
   * @return The created logical time
   **/  
  async command tos_time_t SimpleTime.create(uint32_t high, uint32_t low)
  {
	tos_time_t result;

    	result = low;
    	return result;
    	
// UPLNE SMAZAT TUHLE METODU MOZNA, ZATIM SE TAM NEKDE POUZIVA !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  	
  }
  default event void SimpleTime.sigtdmatimecoming()
  {
  }

}
