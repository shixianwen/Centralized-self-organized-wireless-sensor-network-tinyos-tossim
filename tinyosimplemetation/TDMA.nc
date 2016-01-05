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
 * TDMA Interface
 *
 * Time Division Multiple Access module. 
 * Continuously determines the slot time and signals when a time slot has passed.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


//includes TDMA;
#include "TDMA.h"

interface TDMA
{
  /**
   * Starts the TDMA mechanism.
   *
   * @param sSlot Starting slot number. If the slot is bigger than sFrame, it is adjusted to a valid slot within sFrame.
   *
   * @param sFrame Frame length.
   *
   * @param sInterval Slot time length.
   * @return <code>SUCCESS</code> if TDMA is started. Else,
   *        <MENU>
   *        <LI>TDMA_E_INVALID_INTERVAL if the value of interval is not between MIN_INTERVAL and MAX_INTERVAL (<code>TDMA.h</code>).
   *        <LI>TDMA_E_INVALID_FRAME_LENGTH if the frame length is below MIN_FRAME_LENGTH (<code>TDMA.</code>).
   *        <LI>Error messages from the interface <code>Timer.start()</code>.
   **/
  command error_t start(tSlot sSlot, tFrame sFrame, uint16_t sInterval);

  /**
   * Stops the TDMA mechanism.
   *
   * @return SUCCESS if stopped. FAIL if failed to stop dur to internal error.
   **/
  command error_t stop();

  /**
   * Changes the interval length of a slot. The change of the interval will not be in affect before the next slot event.
   *
   * @param newInterval The new slot time.
   *
   * @return <code>SUCCESS</code> if changed. Else,
   *         <MENU>
   *         <LI>TDMA_E_INVALID_INTERVAL if the value of interval is not between MIN_INTERVAL and MAX_INTERVAL (<code>TDMA.h</code>).
   *         <LI>Error messages from the interface <code>Timer.start()</code>.
   **/
  command error_t setInterval(uint16_t newInterval);

  /**
   * Gives the current slot interval
   *
   * @return Slot interval.
   */
  command uint16_t getInterval();

  /**
   * Changes the frame length.
   *
   * @param newFrame The new frame length.
   *
   * @return <code>SUCCESS</code> if changed. Else, 
   *        <LI>TDMA_E_INVALID_FRAME_LENGTH if the frame length is below MIN_FRAME_LENGTH (<code>TDMA.</code>).
   **/
  command error_t setFrame(tFrame newFrame);

  /**
   * Gives the current frame length.
   *
   * @return Current frame length.
   */
  command tFrame getFrame();

  /**
   * Adjust the interval for one interval only. The adjustment of the interval will not be in affect before the next slot event.
   *
   * @param msAdjust Adjustment in milliseconds. Positive/Negative argument advances/regresses the interval.
   *
   * @return <code>SUCCESS</code> if it will be adjusted. Else,
   *         <LI><code>TDAM_E_INVALID_ARGUMENT</code> if <code>msAdjust</code> is 0 or not between MIN_ADJUST (<code>TDMA.h</code>) and interval 
   * 
   **/
  command error_t adjust(int16_t msAdjust);

  /**
   * Returns the current local time
   */
  command tTime getLocalTime();

  /**
   * Sets the local time to the given time argument.
   *
   * @param t Binary milliseconds of typy tos_time_t (tTime).
   **/
  command void setLocalTime(tTime t);

  /**
   * Signals when a new slot has commenced.
   *
   * @param slot current slot
   *
   * @return Always <code>SUCCESS</code>
   **/
  event void sigNewSlot(tSlot slot);
  
}
