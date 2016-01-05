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
 * TDMA Module
 *
 * Time Division Multiple Access module. 
 * Continuously determines the slot time and signals when a time slot has passed.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


//includes TDMA;
#include "TDMA.h"

module TDMAC
{
  provides
  {
  	interface TDMA;  
  }

  uses
  {
  	interface Boot;
  	interface SimpleTime;
	interface Timer<TMilli> as Timer;
	
	interface Leds;
	
	// Printf
//    	interface SplitControl as PrintfControl;
//    	interface PrintfFlush;	
  }
}

implementation
{
  uint16_t interval;
  tFrame frame;
  bool bIntChanged;
  bool bRunning;
  
  /**
   * Initialize the component.
   * 
   * @return none
   **/
  event void Boot.booted()
  {
  	interval = DEFAULT_INTERVAL;
	frame = MIN_FRAME_LENGTH;
	bIntChanged = FALSE;
	bRunning = FALSE;
	 
//	call PrintfControl.start();
		 
	return;	
  }
  
//  event void PrintfControl.startDone(error_t error)
//  {
//  	printf("\n Printf in TDMAC started!!");
//  	call PrintfFlush.flush();
//  }  
  
//  event void PrintfControl.stopDone(error_t error) 
//  {
//  }
  
//  event void PrintfFlush.flushDone(error_t error) 
//  {
//  }
  
  
  
  

  /**
   * Event handler from the timer.
   **/
  event void Timer.fired()
  {
  	tSlot currentSlot;
	tTime lTime;
	tTime t;

	if(bIntChanged == TRUE)
	{	
		//把现在的时间间隔调整成设置的
		//cange the interval to the new requested one
		call Timer.startPeriodic(interval);
		
		bIntChanged = FALSE;
		return;
	}
	//返回现在的tos_time_t
	lTime = call SimpleTime.get();
	
	//find the diviation
	//看现在的时间和interval的时间相差多少。
	t = lTime % interval;

	if(t < interval/2)
		//预计时间时间来晚了，则刚好是这个时刻
		call Timer.startPeriodic((interval - t));
	else	
		//比预计时间来早了，还在前一个slot，则要在后面一个slot fire
		call Timer.startPeriodic((2 * interval - t));

	//Add time for error margin
	//为时间进行错误修正，确保得到的是正确的time slot
	lTime = call SimpleTime.addUint32(lTime, (interval/2));
	//多少个时隙已经过去了
	//interval是一个slot的长度
	//Get the number of slots that has passed since the beginning
	lTime = lTime / interval;
	//得到现在是第几个slot在一个帧中
	//get current slot within the frame
	currentSlot = lTime % frame;
	//发信号说明一个新的slot已经开始了
	//Signal all interested that a new slot has started.
	signal TDMA.sigNewSlot(currentSlot);

	return;
  }

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
   *        <LI>TDMA_E_ALREADY_RUNNING The TDMA is active. Please stop it first by using <code>stop()</code>.
   *        <LI>TDMA_E_INVALID_INTERVAL if the value of interval is not between MIN_INTERVAL and MAX_INTERVAL (<code>TDMA.h</code>).
   *        <LI>TDMA_E_INVALID_FRAME_LENGTH if the frame length is below MIN_FRAME_LENGTH (<code>TDMA.</code>).
   *        <LI>Error messages from the interface <code>Timer.start()</code>.
   **/
   //开始TDMA的scheme
  command error_t TDMA.start(tSlot sSlot, tFrame sFrame, uint16_t sInterval)
  {	
	//TDMA已经开始了
  	if(bRunning == TRUE)
		return TDMA_E_ALREADY_RUNNING;
	
	//设置的这个slot的时间小于了最小时隙或者大于了最大时隙
	if(sInterval < MIN_INTERVAL || sInterval > MAX_INTERVAL)
		return TDMA_E_INVALID_INTERVAL;
	//最小的帧长度小于了最小帧长度，返回错误
	if(sFrame < MIN_FRAME_LENGTH)
		return TDMA_E_INVALID_FRAME_LENGTH;
	//把参数设定
	//Set parameters
	frame = sFrame;
	interval = sInterval;

	//Adjust slot just in case
	//currentSlot = sSlot % frame;
	//让时钟在每个时隙都fire一次
	//all ok so start the timer
	call Timer.startPeriodic(interval);
	//预示着TDMA开始了
	bRunning = TRUE;

	//all ok so start the timer
	return SUCCESS;
  }

  /**
   * Stops the TDMA mechanism.
   *
   * @return SUCCESS if stopped. FAIL if failed to stop dur to internal error.
   **/
   //停掉TDMA
  command error_t TDMA.stop()
  {
  	bRunning = FALSE;
	call Timer.stop();
	return SUCCESS;
  }

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
   //改变TDMA SLOT的时隙的长度
  command error_t TDMA.setInterval(uint16_t newInterval)
  {
  	//valid?
	if(newInterval < MIN_INTERVAL || newInterval > MAX_INTERVAL)
		return TDMA_E_INVALID_INTERVAL;

	//change interval
	interval = newInterval;

	bIntChanged = TRUE;
  }

  /**
   * Gives the current slot interval
   *
   * @return Slot interval.
   **/
   //得到现在的slot的长度
  command uint16_t TDMA.getInterval()
  {
	 return interval;
  }

  /**
   * Changes the frame length.
   *
   * @param newFrame The new frame length.
   *
   * @return <code>SUCCESS</code> if changed. Else, 
   *        <LI>TDMA_E_INVALID_FRAME_LENGTH if the frame length is below MIN_FRAME_LENGTH (<code>TDMA.</code>).
   **/
   //改变一个帧的长度
  command error_t TDMA.setFrame(tFrame newFrame)
  {
	//valid?
	if(newFrame < MIN_FRAME_LENGTH || newFrame > MAX_FRAME_LENGTH)
		return TDMA_E_INVALID_FRAME_LENGTH;

	//Change the frame length
	frame = newFrame;
	
	return SUCCESS;
  }

  /**
   * Gives the current frame length.
   *
   * @return Current frame length.
   **/
   //得到帧的长度
  command tFrame TDMA.getFrame()
  {
	 return frame;
  }

  /**
   * Adjust the interval for one interval only. The adjustment of the interval will not be in affect before the next slot event.
   *
   * @param msAdjust Adjustment in milliseconds. Positive/Negative argument advances/regresses the interval.
   *
   * @return <code>SUCCESS</code> if it will be adjusted. Else,
   *         <LI><code>TDAM_E_INVALID_ARGUMENT</code> if <code>msAdjust</code> is 0 or not between MIN_ADJUST (<code>TDMA.h</code>) and interval 
   * 
   **/
   //只改变下一个TDMA时隙的长度，正值是将time提前了，负值是把time减退了
  command error_t TDMA.adjust(int16_t msAdjust)
  {
	call SimpleTime.adjust(msAdjust);

	return SUCCESS;
  }

  /**
   * Returns the current local time
   **/
   //返回现在的当地时间
  command tTime TDMA.getLocalTime()
  {
	return call SimpleTime.get();
  }

  /**
   * Sets the local time to the given time argument.
   *
   * @param t Binary milliseconds of typy tos_time_t (tTime).
   **/
   //改变节点的当地时间
  command void TDMA.setLocalTime(tTime t)
  {
	call SimpleTime.set(t);
  }

  /**
   * Signals when a new slot has commenced.
   *
   * @param slot current slot
   *
   * @return Always <code>SUCCESS</code>
   **/
   //这个event是放在调用它的程序里处理
   event void SimpleTime.sigtdmatimecoming(){
   
   }
  default event void TDMA.sigNewSlot(tSlot slot)
  {
  }
  
}

