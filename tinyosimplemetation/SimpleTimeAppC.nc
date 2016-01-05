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
 * SimpleTime Configuration
 *
 * Time manipulations and calculations.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/

configuration SimpleTimeAppC
{
  provides interface SimpleTime;
}

implementation 
{
  components MainC, SimpleTimeC,
  	new TimerMilliC() as Timer0;

  components LedsC;

  SimpleTimeC.Leds->LedsC;

  SimpleTimeC -> MainC.Boot;
  SimpleTimeC.Timer0 -> Timer0;
   
  SimpleTime = SimpleTimeC;
}

