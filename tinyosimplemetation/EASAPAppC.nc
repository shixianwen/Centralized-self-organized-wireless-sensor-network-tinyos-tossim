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
 * EASAP Configuration
 *
 * Extended Adaptive Slot Assignment Protocol, E-ASAP, is a defined protocal
 * using the Time Division Multiple Access, TDMA, protocol for improving the
 * channel utilisation by considering the autonomous behaviour of nodes
 * in a Wireless Sensor Network.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


configuration EASAPAppC
{
  provides
  {
  	interface EASAP;
	interface EASAPImp;
  }
}

implementation 
{
  components MainC, EASAPC,
  	SimpleTimeAppC; //Time manipulations/calculations
	 
  components LedsC;

  // Random
  components RandomC;
  components new TimerMilliC() as RandTimerC; // Random time for getting new slot
  
  // Printf	
//  components PrintfC;  	      
      
  EASAPC.Leds -> LedsC;  
  
  EASAPC -> MainC.Boot;

  EASAPC.SimpleTime -> SimpleTimeAppC;

  // Random
  EASAPC.Random -> RandomC;
  EASAPC.RandTimer -> RandTimerC;

  // Printf
//  EASAPC.PrintfControl -> PrintfC;
//  EASAPC.PrintfFlush -> PrintfC;

  //Interface to the public
  EASAP = EASAPC.EASAP;
  EASAPImp = EASAPC.EASAPImp;
}
