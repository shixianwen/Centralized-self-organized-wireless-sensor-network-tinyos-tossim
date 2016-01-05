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
 * EASAP Module
 *
 * Extended Adaptive Slot Assignment Protocol, E-ASAP, is a defined protocal 
 * using the Time Division Multiple Access, TDMA, protocol for improving the 
 * channel utilisation by considering the autonomous behaviour of nodes 
 * in a Wireless Sensor Network.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


//includes EASAP;
#include "EASAP.h"

module EASAPC
{
  provides
  {
  	interface EASAP; //For interfacing with the module
	interface EASAPImp; //For internal implementation
  }

  uses
  {
  	interface Boot;
	interface SimpleTime;
	
	interface Leds;
	
	// Random
    	interface Random;
   	interface Timer<TMilli> as RandTimer;	

	// Printf
//    	interface SplitControl as PrintfControl;
//    	interface PrintfFlush;	   	   	
  }
}

implementation
{
  //INF Structure
  //用来存放本节点的slots和相邻节点slots的信息
  struct Node inf;
  //用来存放frame maximum fram 和current slot的长度
  struct DAT dat;
  //用来判断预留的slot
  bool reservedSlot[MAX_FRAME_LENGTH]; // FALSE - not reserved
  uint16_t occupSlots[MAX_FRAME_LENGTH];
  	
  //task void updateFrame();
  
  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  event void Boot.booted()
  {
  	//Initialise INF
	//初始化本节点
	inf.id = TOS_NODE_ID;
	inf.slots = NULL;
	inf.frame = MIN_FRAME_LENGTH;

	memset(&inf.timeStamp, 0, sizeof(tTime));
	memset(reservedSlot, FALSE, MAX_FRAME_LENGTH);
		 	 
	inf.neighbour = FALSE;
	 
	inf.prev = NULL;
	inf.next = NULL;
	
//	call PrintfControl.start();	
	 
	return;	
  }

//  event void PrintfControl.startDone(error_t error)
//  {
//  	printf("\n Printf in EASAPC started!!");
//  	call PrintfFlush.flush();
//  }  
  
//  event void PrintfControl.stopDone(error_t error) 
//  {
//  }
  
//  event void PrintfFlush.flushDone(error_t error) 
//  {
//  }    
  
  
  


  /**
   * Initializes the settings for an individual node.
   *
   * @param pNode Node to initialize. Discarded if <code>NULL</code>.
   **/
  command void EASAPImp.initNode(struct Node* pNode)
  {
 
  	//Invalid Node
	if(pNode == NULL)
		return;

  	pNode->id = 0;
	pNode->slots = NULL;
	pNode->frame = MIN_FRAME_LENGTH;
	  
	memset(&pNode->timeStamp, 0, sizeof(tTime));
	  
	pNode->neighbour = FALSE;
	  
	pNode->prev = NULL;
	pNode->next = NULL;
  }

  /** Adds a slot to the given node. Discarded if  no memory is available for it.
   *
   * @param slot Slots to be added.
   *
   * @param pNode Reference to node.
   *
   * @return <code>SUCCESS</code> if added. 
   *         <code>EASAP_SLOT_EXISTS</code> if it already exists.
   *         <code>EASAP_SLOT_DISCARDED</code> if NOT added due to memory limitations.
   *         <code>EASAP_SLOT_RESERVED</code> if slot is reserved.   
   **/
  command error_t EASAPImp.addSlot(tSlot slot, struct Node* pNode)
  {  
  	struct Slot *pCurrent = pNode->slots;

	if(reservedSlot[slot] == TRUE)
		return EASAP_SLOT_RESERVED;	  
	  	  	  
	//Any slots in the list	  
	if (pCurrent == NULL)
	{
		//Allocate memory		 
		pCurrent = malloc(sizeof(struct Slot));

		if (pCurrent == NULL)
			return EASAP_SLOT_DISCARDED; //Out of memory

		//make sure
		pCurrent->next = NULL;

		//assign slot
		pCurrent->slot = slot;
			
		//Give back new reference to the list
		pNode->slots = pCurrent;
	}
	else
	{
		if(call EASAPImp.findSlot(slot, pNode) != NULL)
			return EASAP_SLOT_EXISTS; //already exists

		//Find the last assigned slot
		while (pCurrent->next != NULL)
			pCurrent = pCurrent->next;

		//Allocate memory
		pCurrent->next = malloc(sizeof(struct Slot));
		 
		if (pCurrent->next == NULL)
			return EASAP_SLOT_DISCARDED; //Out of memory

		//make sure
		pCurrent->next->next = NULL;

		//assign slot
		pCurrent->next->slot = slot;
		pCurrent->next->prev = pCurrent;
	}
	 
	return SUCCESS;
  }

  /** Adds the given slots to the Slot list.
   *
   * @param slots Slots to be added. First value in the stream determines how many slots there are in the stream.
   *
   * @return <code>TRUE</code> if all slots where added.
   *         <code>FALSE</code> if at least one was not added due to memory.
   **/
  command bool EASAPImp.addSlots(tSlot* slots, struct Node* pNode)
  {
  	int i;
	tSlot nrOfSlots = *slots;

	//Add all the slots
	  
	for (i = 0; i < nrOfSlots; i++)
	{
		//Next slot
		slots++;

		if(call EASAPImp.addSlot(*slots, pNode) == EASAP_SLOT_DISCARDED)
			return FALSE; // Out of memory
	}

	return TRUE;
  }

  /** Removes the slot from the node
   *
   * @param slot Slot number to remove.
   *
   * @param pNode reference to the node to remove the slot from.
   *
   * @return <code>TRUE</code> if removed.
   *         <code>FALSE</code> otherwise.
   **/
   //删除slot
  command bool EASAPImp.removeSlot(tSlot slot, struct Node* pNode)
  {
  	struct Slot *pSlot;
	//struct Slot *prev;
	//返回了一个指向slot*的一个指针
	pSlot = call EASAPImp.findSlot(slot, pNode);
	
	if(pSlot == NULL)
		return FALSE; //slot not found
	  
	//Is it the first slot in the list?
	if (pSlot == pNode->slots)
	{
		pNode->slots = pNode->slots->next;
		pNode->slots->prev = NULL;
	}
	else
	{	
		//Ignore this slot
		if(pSlot->prev != NULL)
			pSlot->prev->next = pSlot->next;
		 
		if(pSlot->next != NULL)
			pSlot->next->prev = pSlot->prev;
	}

	//Remove found item
	free(pSlot);

	//Decrease frame if possible
	//post updateFrame();

	return TRUE;
  }

  /**
   * Clears all the slots from the given node.
   *
   * @param pNode Node to clear the slots from. Discarded if <code>NULL</code>.
   **/
   //删除这个节点的所有slots
  command void EASAPImp.clearSlots(struct Node* pNode)
  {
  	struct Slot *pCurrent, *pNext;
	
	//Invalid node
	if(pNode == NULL)
		return;

	pCurrent = pNode->slots;
	 
	//remove all alocated slots
	while (pCurrent != NULL)
	{
		//Remember next slot before clearing
		pNext = pCurrent->next;
		 
		//clear
		free(pCurrent);
		 
		//next
		pCurrent = pNext;
	}
  }

  /** Searches the node for the given slot.
   *
   * @param slot Slot to find.
   *
   * @param pNode reference to find the slot in. Discarded if <code>NULL</code>
   *
   * @return Reference to the found slot, <code>NULL</code> if not found.
   **/
   //找到这个节点所占的slot
  command struct Slot* EASAPImp.findSlot(tSlot slot, struct Node* pNode)
  {
  	struct Slot* pSlot;

	//Invalid node
	if(pNode == NULL)
		return NULL;

	pSlot = pNode->slots;
 
	//Search for the slot
	while (pSlot != NULL)
	{
		if (pSlot->slot == slot)
			return pSlot; //Slot found
		 
		pSlot = pSlot->next;
	}
	  
	return NULL; //Slot not found 
  }

  /** Appends the given node to the INF list.
   *
   * @param node Node to be added to the inf list.
   *
   * @return <code>TRUE</code> if added.
   *         <code>FALSE</code> otherwise.
   **/
   //添加一个邻居节点，可以放在主程序里，收到了thinknode发来的包的时候添加
  command bool EASAPImp.appendNode(struct Node* pNode)
  {
	struct Node *pCurrent = &inf;

	if(pNode == NULL)
		return FALSE;

	// Locate the last node
	while (pCurrent->next != NULL)
		pCurrent = pCurrent->next;

	//Add at then end of the list
	pNode->prev = pCurrent;

	pCurrent->next = pNode;
	
	return TRUE;
  }

 command void EASAP.setFrame(uint16_t frame)
  {
  	if(inf.frame >= MAX_FRAME_LENGTH)
		return;
	  
	//改变本节点frame的长度
	inf.frame = frame;
	dbg("lab1","currentframe length is %d\n", inf.frame);

	//Let all know
	signal EASAP.frameseted(inf.frame);
  }
  /**
   * Increases the frame length.
   **/
   //在我的程序里基本不需要。他主动增加了frame的长度
   /*我需要的是一个更新frame长度的*************************/
  /*command void EASAPImp.increaseFrame()
  {
  	if(inf.frame >= MAX_FRAME_LENGTH)
		return;
	  
	//increase the frame length
	inf.frame = inf.frame * CHANGE_FRAME_BY;

	//Let all know
	signal EASAP.frameChanged(inf.frame);
  }*/

  /**
   * Decreases the frame length.
   **/
   //在我的程序里基本不需要。他主动减少了frame的长度
   /*我需要的是一个更新frame长度的**************/
  /*command void EASAPImp.decreaseFrame()
  {    	
  	if(inf.frame <= MIN_FRAME_LENGTH)
		return;
		
	//Decrease the frame length
	inf.frame = inf.frame / CHANGE_FRAME_BY;

	//Let all know
	signal EASAP.frameChanged(inf.frame);
  }*/

  /** 
   * Updates the frame length if possible.
   **/
   //我的代码里不需要这个更新frame，我是通过接收到的消息来用
   /*
  task void updateFrame()
  {
  	bool allLess = TRUE;
	bool morePossible = TRUE;
	  
	uint8_t i, repeat, frameHalf;
	
	struct Node* pNode;
	struct Slot* pSlot;
	struct NodeInfo occupiedSlots[MAX_FRAME_LENGTH];

	//Already at minimum frame length?
	if(inf.frame <= MIN_FRAME_LENGTH)
		return;

	//Clear all info
	memset(occupiedSlots, 0, MAX_FRAME_LENGTH * sizeof(struct NodeInfo));
	  
	//Set own slots
	pSlot = inf.slots;
	
	//Mark all information of occupied of own slots
	while (pSlot != NULL)
	{
		occupiedSlots[pSlot->slot].id = inf.id;
		occupiedSlots[pSlot->slot].slot = pSlot->slot;
			
		pSlot = pSlot->next;
	}

	pNode = inf.next;
	while (pNode != NULL)
	{
		//Mark all nodes with their ID and corresponding slot		
		pSlot = pNode->slots;
		while (pSlot != NULL)
		{
			if(pNode->neighbour == TRUE && allLess == TRUE && pNode->frame >= inf.frame)
				allLess = FALSE;

			repeat =  inf.frame / pNode->frame - 1;
			
			occupiedSlots[pSlot->slot % inf.frame].id = pNode->id;
			occupiedSlots[pSlot->slot % inf.frame].slot = pSlot->slot;
			
			//Repeat slot in multiple frame length
			while (repeat > 0)
			{
				occupiedSlots[(pSlot->slot + (pNode->frame * repeat)) % inf.frame].id = pNode->id;
				occupiedSlots[(pSlot->slot + (pNode->frame * repeat)) % inf.frame].slot = pSlot->slot;

			  	repeat--;
			}

			pSlot = pSlot->next;
		}

		pNode = pNode->next;
	}

	//Decrease frame length as much as possible
	while (morePossible == TRUE)
	{
		//Decrease frame length if all nodes in the neighbourhood area are less
		if(allLess == TRUE)
		{
			//Check also that this node doesn't have an extra slot in the latter half
			pSlot = inf.slots;
			while(pSlot != NULL)
			{
				if(pSlot->slot >= (inf.frame / CHANGE_FRAME_BY))
			  	{	
					morePossible = FALSE;
					break;
			  	}

				pSlot = pSlot->next;
			}

			if(morePossible == TRUE)
			{
				call EASAPImp.decreaseFrame();

			  	//Minimum frame length reached?
				if(inf.frame <= MIN_FRAME_LENGTH)
				return;
			}
		}

		//Check if the frame are identical in both halves
		else if(occupiedSlots[inf.frame / CHANGE_FRAME_BY].id == 0)
		{
			frameHalf = inf.frame / CHANGE_FRAME_BY;
			
			for(i = 1;i < frameHalf;i++)
			{
				//Are the slot in former and latter half the same?
			  	if(occupiedSlots[i].id != occupiedSlots[i + frameHalf].id ||
					occupiedSlots[i].slot != occupiedSlots[i + frameHalf].slot )
			  	{
					//is the slot in latter half empty?
				 	if(occupiedSlots[i+frameHalf].id != 0)
				 	{
						morePossible = FALSE;
						break;
				 	}
			  	}
			}
			
			if(morePossible == TRUE)
			{		
				call EASAPImp.decreaseFrame();

			  	//Minimum frame length reached?
			  	if(inf.frame <= MIN_FRAME_LENGTH)
					return;
			}
			 
		}
		
		//Not possible to decrease
		else
			morePossible = FALSE;
	}
  }*/

  /** 
   * Increases the frame length.
   **/
   //不需要这个
 /*command void EASAP.sigSlotZero()
  {
	call EASAPImp.increaseFrame();
  }*/

  /**
   * Gives the reference to the INF list.
   *
   * @return Reference to the list. NULL if empty 
   **/
   //返回存储node的信息，这个需要
  command struct Node* EASAP.getINF()
  {
	return &inf;
  }

  /**
   * Gives the DAT info EXCEPT the currentSlot.
   *
   * @return DAT structure defined in <code>EASAP.h</code> 
   **/
   //用来返回周围节点的最大frame这个我也不需要
   //因为我不用节点在做判断
  /*command struct DAT* EASAP.getDAT()
  {
	struct Node* pNode = inf.next;

	dat.frame = inf.frame;
	dat.maxFrame = inf.frame;

	while(pNode != NULL)
	{
		if(pNode->neighbour == TRUE)
			if(dat.maxFrame < pNode->frame)	 //Update if node has bigger frame length
				dat.maxFrame = pNode->frame;

		pNode = pNode->next;
	}
	  
	return &dat;
  }*/

  /** Gets a slot and assigns it to itself, if possible.
   *
   * @param slotNr slot number if successfull. 0 if not found.
   *
   * @return <code>TRUE</code> if found. <code>FALSE</code> if not (Max frame length has been reached).
   **/
   //自己主动的给自己分配一个slot，暂时不需要。
   //我可能需要的是，随机给自己分配一个slot上传信息
  /*command bool EASAP.getSlot(tSlot* slotNr)
  {
	int8_t i, repeat;

	bool slot[MAX_FRAME_LENGTH];
	tFrame frame = inf.frame;

	struct Node* pNode;
	struct Slot* pSlot;
	  
	*slotNr = 0;

	//Get a slot within max allowed frame length
	while (frame <= MAX_FRAME_LENGTH)
	{
		//Start from the beginning
		pNode = inf.next;
		memset(slot, FALSE, MAX_FRAME_LENGTH * sizeof(bool));

		//Set own slots
		pSlot = inf.slots;

		while (pSlot != NULL)
		{
			slot[pSlot->slot % frame] = TRUE;
			
			pSlot = pSlot->next;
		}
		 
		//Set all assigned slots as occupied
		while (pNode != NULL)
		{
			pSlot = pNode->slots;
			
			//all slots of the node
			while (pSlot != NULL)
			{
				repeat =  frame / pNode->frame - 1;
			  
				slot[pSlot->slot % frame] = TRUE;
			  
			  	//Repeat slot in multiple frame lengths
			  	while (repeat > 0)
			  	{
					slot[(pSlot->slot + (pNode->frame * repeat)) % frame] = TRUE;

				 	repeat--;
			  	}

				//next slot
				pSlot = pSlot->next;
			}

			//next node
			pNode = pNode->next;
		}

		//search for an empty slot
		for (i = 1; i < frame; i ++)
		{
			if (slot[i] == FALSE && reservedSlot[i] == FALSE)
			{
				*slotNr = i; //Found one

			  	//Assign a new slot to itself
			  	call EASAPImp.addSlot(i, &inf);

			  	//See the required frame length
			  	if(inf.frame != frame)
			  	{
					inf.frame = frame;

					//let all know that frame has changed
					signal EASAP.frameChanged(inf.frame);
				}
			  
			  	return TRUE;
			}
		}
		
		//No slot found, increase frame;
		frame = frame * CHANGE_FRAME_BY;
	}

	return FALSE; //not found
  }*/

  /** Gets a slot with random time delay and assigns it to itself, if possible.
   *
   **/
  /*command void EASAP.getNewSlotRandTime()
  {
	uint16_t randTime;	
	
	do
	{
		randTime = call Random.rand16();
	}while(randTime<MIN_TIME_RAND_SLOT || randTime>MAX_TIME_RAND_SLOT);
			
	call RandTimer.startOneShot((uint32_t)randTime);					  
  }*/

  /** Random time delay fired
   *
   **/
  event void RandTimer.fired()
  {
	//tSlot randSlot;
	
  	//call EASAP.getSlot(&randSlot);
				  	
  	return;
  }

  /** Release all owned slots
   *
   **/
   //放弃所有自己拥有的slots
  command void EASAP.releaseOwnedSlots()
  {
	struct Node* pThisNode;
	struct Slot* pMySlots;

	pThisNode = call EASAP.getINF();
	pMySlots = pThisNode->slots;
	
	while(pMySlots != NULL)
	{	
		call EASAP.removeSlot(pMySlots->slot);
		
		pMySlots = pMySlots->next; //next slot
	}	
  }  
      
  /** Release slots from upper half of frame
   *
   **/
   //这个丢弃前半个frame的slot对我也没有用
  /*command void EASAP.releaseUpperSlots()
  {
	struct Node* pThisNode;
	struct Slot* pMySlots;
	
	pThisNode = call EASAP.getINF();
	pMySlots = pThisNode->slots;
	
	while(pMySlots != NULL)
	{
		if(pMySlots->slot >= pThisNode->frame / 2)
		{		
			call EASAP.removeSlot(pMySlots->slot);
			
			call EASAP.getNewSlotRandTime();
			
		}
		
		pMySlots = pMySlots->next; //next slot
	}	
  }  */

  /**
   * Return the current set maximum frame length.
   **/
   //返回可以执行的最大的帧长度
  command tFrame EASAP.getMaxFrameLength()
  {
	return MAX_FRAME_LENGTH;
  }

  /** Determines if the given slot is owned by the node.
   *
   * @return <code>TRUE</code> if it is. Else <code>FALSE</code>.
   **/
   //判断是不是自己的slot
   /*********************我还需要一个command判断是不是邻居的发送信息时间************************/
    /*********************简化为，一直听就好了。。反正模拟又不费电，节点一直是开着的************************/
  command bool EASAP.isOwnSlot(tSlot slot)
  {
	struct Slot* pSlot = inf.slots;
	while(pSlot != NULL)
	{
		if(pSlot->slot == slot)
		{
			return TRUE; //Found
		}
		//continue searching
		pSlot = pSlot->next;
	}
	
	return FALSE; //not found
  }

  /** Removes own slot from the list, if it exists
   *
   * @param slot Slot to be removed.
   *
   * @return TRUE if removed. FALSE if not found.
   **/
   //它用来判断可不可以跟新frame的，我不理它，直接用EASAPImp做就好了
  command bool EASAP.removeSlot(tSlot slot)
  {
	struct Slot* pSlot = inf.slots;
	  
	while(pSlot != NULL)
	{
		//Found?
		if(pSlot->slot == slot)
		{	
			call EASAPImp.removeSlot(slot, &inf); //Found

			//check if the frame can be reduced
			//post updateFrame();

			return TRUE;
		}
		 
		//continue searching
		pSlot = pSlot->next;
	}
	
	return FALSE;
  }

  /** Updates the given node's information to the INF list appropriately as defined in E-ASAP protocol. If the node doesn't exist in the list, it is added as new.
   *
   * @param id ID of the node.
   *
   * @param pSlots Slots assigned to the node. Initial paramater must contain the number of slots that are in the  stream
   *
   * @param frameLength Frame assigned to the node.
   *
   * @param cLocalTime Current Local Time.
   *
   * @param isNeighbour Is it a neighbour to the current node (Broadcasting node)
   *
   * @return <code>TRUE</code> if added/updated. 
   *         <code>FALSE</code> if: - It already exists
   *                   - No memory available
   *                   - Any of id/slot/frame is invalid.
   **/
   command void EASAPImp.updateMyNodeInfo(tID id, tSlot* slots, tFrame frame, 
							 tTime* cLocalTime, nx_uint8_t isNeighbour)							 
  {
	uint16_t i;
	uint16_t nrOfSlots = *slots;
	tSlot* rSlot;
	bool bSlotRemoved = FALSE;
	 
	struct Node* pNode = NULL;
	struct Slot* lSlot;

	//Does it exist?
	pNode = &inf;
	if (pNode == NULL)
		return; //no, discard request
	  
	//Update changes in frame length
	if (frame != pNode->frame)
		pNode->frame = frame;
	  
	rSlot = slots + 1;
	 
	lSlot = pNode->slots;
	  
	//Remove slots from the node in INF if it doesn't exist in the stream
	while (lSlot != NULL)
	{
		for (i = 0; i < nrOfSlots; i++)
		{
			//slot already exists?
			if (lSlot->slot == *rSlot)
				break;

			rSlot++;
		}
		//发现这个老的的原来有的slot不存在INFlist中,说明这个节点自己取消了这个slot传输，删掉老旧的节点
		//remove old slot from the node in INF
		if (i == nrOfSlots)
		{
			call EASAPImp.removeSlot(lSlot->slot, pNode); //Remove it

			bSlotRemoved = TRUE;
		}
		 
		lSlot = lSlot->next;
	}

	rSlot = slots + 1;
	 
	//Add new slots to the node in INF
	//把新的节点都加进去
	/*************slots的消息格式，第一个值是有多少个slots，然后才是slots具体每一个每一个的值************/
	for (i = 0;i < nrOfSlots;i++)
	{
		if (call EASAPImp.findSlot(*rSlot, pNode) == NULL)
			call EASAPImp.addSlot(*rSlot, pNode);
		 
		rSlot++;
	}

	//check if frame length can be reduced
	//我不需要干这一步，不需要减少frame的长度。我是根据得到的frame长度来跟新的消息
	/*if(bSlotRemoved == TRUE)
	{	
		post updateFrame();
	}*/
  }
   //用来跟新本节点周围邻居节点的信息
   /********************************我要把它改成也可以用来跟新自己的节点信息*/
  command bool EASAP.updateNode(tID id, tSlot* slots, tFrame frameLength, 
						tTime* cLocalTime, uint8_t isNeighbour)						
  {
	struct Node* pNode = NULL;
	
	
	  
	//None of the vital information should be zero
	if (id == 0 || slots == NULL || *slots == 0 || frameLength == 0)
		return FALSE;

	//*************这里需要修改，不能忽略自己的信息
	if(id == TOS_NODE_ID){
		call EASAPImp.updateMyNodeInfo(id, slots, frameLength, cLocalTime, isNeighbour);
	}
		
	//Does it already exist?
	pNode = call EASAP.findNode(id);

	//if extist, update information
	//判断这个节点以前是不是我的邻居，如果是，更新信息
	if (pNode != NULL)
	{
		//has the node moved to be as a neighbour?
		if(isNeighbour == TRUE && pNode->neighbour == FALSE)
			pNode->neighbour = TRUE;
		 
		if(isNeighbour == TRUE || pNode->neighbour == FALSE)
			pNode->timeStamp = *cLocalTime;

		call EASAPImp.updateNodeInfo(id, slots, frameLength, cLocalTime, isNeighbour);
		return TRUE;
	}
	//如果此节点以前不是我的邻居节点，添加一个新的节点
	//Allocate space for new node
	pNode = malloc(sizeof(struct Node));

	if (pNode == NULL)
		return FALSE; //Out of memory

	//Clear its content
	call EASAPImp.initNode(pNode);

	//Set node's id
	pNode->id = id;

	//Set slots
	call EASAPImp.addSlots(slots, pNode);

	//Add frame
	pNode->frame = frameLength;

	//Is it a neighbour to this node?
	pNode->neighbour = isNeighbour;

	//Mark timeStamp
	pNode->timeStamp = *cLocalTime;

	//Add it to the list
	call EASAPImp.appendNode(pNode);

	return TRUE;
  }

  /**
   * Removes the node from the INF list.
   *
   * @param id Node to be removed. Discarded if it doesn't exist
   **/
   //从Infｌｉｓｔ移除一个移除一个节点
  command void EASAP.removeNode(tID id)
  {
	struct Node* pNode;
	 
	pNode = call EASAP.findNode(id);
	  
	if (pNode != NULL)
	{
		//first node?
		if(pNode->prev != NULL)
			pNode->prev->next = pNode->next; //Ignore me if you are before me

		//last node?
		if (pNode->next != NULL)
			pNode->next->prev = pNode->prev; //Ignore me if you're after me
		 
		//remove slots
		call EASAPImp.clearSlots(pNode);
		 
		//now it's safe
		free(pNode);
	}
  }

  /** Updates nodes information received from the transmission to the node information in the INF. Discarded if the node doen't exist.
   *
   * @param id ID of the node.
   *
   * @param slots Slots received. First byte MUST contains the nr of slots there are in the stream.
   *
   * @param frame Frame length received.
   *
   * @param cLocalTime Current Local Time.
   **/
   //我可以使用这个来跟新本节点邻居节点的slot信息，第一次加入也可以用此方法，没有关系。不碍事
  command void EASAPImp.updateNodeInfo(tID id, tSlot* slots, tFrame frame, 
							 tTime* cLocalTime, nx_uint8_t isNeighbour)							 
  {
	uint16_t i;
	uint16_t nrOfSlots = *slots;
	tSlot* rSlot;
	bool bSlotRemoved = FALSE;
	 
	struct Node* pNode = NULL;
	struct Slot* lSlot;

	//Does it exist?
	pNode = call EASAP.findNode(id);
	if (pNode == NULL)
		return; //no, discard request
	  
	//Update changes in frame length
	if (frame != pNode->frame)
		pNode->frame = frame;
	  
	rSlot = slots + 1;
	 
	lSlot = pNode->slots;
	  
	//Remove slots from the node in INF if it doesn't exist in the stream
	while (lSlot != NULL)
	{
		for (i = 0; i < nrOfSlots; i++)
		{
			//slot already exists?
			if (lSlot->slot == *rSlot)
				break;

			rSlot++;
		}
		//发现这个老的的原来有的slot不存在INFlist中,说明这个节点自己取消了这个slot传输，删掉老旧的节点
		//remove old slot from the node in INF
		if (i == nrOfSlots)
		{
			call EASAPImp.removeSlot(lSlot->slot, pNode); //Remove it

			bSlotRemoved = TRUE;
		}
		 
		lSlot = lSlot->next;
	}

	rSlot = slots + 1;
	 
	//Add new slots to the node in INF
	//把新的节点都加进去
	/*************slots的消息格式，第一个值是有多少个slots，然后才是slots具体每一个每一个的值************/
	for (i = 0;i < nrOfSlots;i++)
	{
		if (call EASAPImp.findSlot(*rSlot, pNode) == NULL)
			call EASAPImp.addSlot(*rSlot, pNode);
		 
		rSlot++;
	}

	//check if frame length can be reduced
	//我不需要干这一步，不需要减少frame的长度。我是根据得到的frame长度来跟新的消息
	/*if(bSlotRemoved == TRUE)
	{	
		post updateFrame();
	}*/
  }

  /**
   * Removes all inactive nodes from the INF list. Inactive node is given by all nodes that have older time mark than the given argument.
   *
   * @param tStampMark Time mark. Oldest allowed time mark for all nodes.
   *
   * @param cLocalTime Current local time.
   **/
   //暂时不需要timemark这个功能，不需要撤销所有过期的节点
   /*
  command void EASAP.removeInactiveNodes(tTime* timeStampMark)
  {
	bool bUpdate = FALSE;
	struct Node* pNode = inf.next;
	 
	uint8_t nrOfInactiveNodes = 0;
	uint16_t inactiveNodes[MAX_FRAME_LENGTH];
	  
	memset(inactiveNodes, 0, MAX_FRAME_LENGTH * sizeof(uint8_t));	 
	 
	//Get all the inactiveNodes
	while (pNode != NULL)
	{
		//Mark node for removal if inactive		
		if (call SimpleTime.compare(pNode->timeStamp, *timeStampMark) == TIME_LESS)
		{
			inactiveNodes[nrOfInactiveNodes] = pNode->id;
			nrOfInactiveNodes++;
		}
		 
		pNode = pNode->next;
	}

	if(nrOfInactiveNodes > 0)
		bUpdate = TRUE;

	//Remove all inactive nodes
	while (nrOfInactiveNodes > 0)
	{
		call EASAP.removeNode(inactiveNodes[nrOfInactiveNodes-1]);
		nrOfInactiveNodes--;
	}
	  
	if(bUpdate == TRUE)
	{		
		post updateFrame(); //Reduce frame length if possible
	}
  }*/

  /** Searches for a node in the INF list.
   *
   * @param id ID of the node.
   *
   * @return Reference to the found node. <code>NULL</code> if not found.
   **/
  command struct Node* EASAP.findNode(tID id)
  {
	struct Node *pCurrent = inf.next;
	  
	while (pCurrent != NULL)
	{
		if (pCurrent->id == id)
			return pCurrent;
		 
		pCurrent = pCurrent->next;
	}
	  
	return NULL;
  }

  /**
   * Signals when frame length has been changed.
   *
   * @param newFrame Frame length of the new frame.
   **/
  default event void EASAP.frameChanged(uint16_t newframe)
  {
  }
  default event void EASAP.frameseted(uint16_t newframe)
  {
  }
  /**
   * Get slots occupied by the node and its neighbours
   *
   * @param slots Reference of slots array.
   *
   * @return Count of occupied slots.
   **/
  command uint16_t EASAP.getOccupiedSlots()
  {
  	uint16_t count = 0;
  	uint16_t i = 0;
  	struct Slot* pSlot = inf.slots;
	struct Node* pNode = &inf;
	
	//CLEAR	
	memset(occupSlots, 0, MAX_FRAME_LENGTH);
		
	do
	{  
		while (pSlot != NULL)
		{
			occupSlots[pSlot->slot]++;

		 	pSlot = pSlot->next;
		}
		pNode = pNode->next;
		pSlot = pNode->slots;
		
	}while(pNode != NULL);	  

	while(i<MAX_FRAME_LENGTH)
	{
		if(occupSlots[i]>0)
		{
			count++;
		}
		i++;
	}

	return count;
		 
  }
  
  /** Reserve slot
   *
   * @param slot Slot to be reserved.
   *
   * @return TRUE if reserved. FALSE if not.
   **/
  command bool EASAP.reserveSlot(tSlot slot)
  {
  	if(slot < 0 || slot >= MAX_FRAME_LENGTH)
		return FALSE;	

	call EASAP.getOccupiedSlots();
  	if(occupSlots[slot] > 0)
		return FALSE;		
	
	reservedSlot[slot] = TRUE;
	
	return TRUE;		
  }
  
  /** Get reserved slots
   *
   * @return pointer to reserved slots array
   **/
  command bool* EASAP.getReservedSlots()
  {
  	return reservedSlot;
  }

  /** Get nr of reserved slots
   *
   * @return nr of reserved slots
   **/
  command uint16_t EASAP.nrOfReservedSlots()
  {
  	uint16_t nr=0;
  	uint16_t i;
  	
  	for(i=0; i<MAX_FRAME_LENGTH; i++)
  	{
  		if(reservedSlot[i]==TRUE)
  		{
  			nr++;
  		}
  	}
  	
  	return nr;
  }
  
  /** Get nr of reserved slots in frame
   *
   * @return nr of reserved slots
   **/
   /*
  command uint8_t EASAP.nrOfReservedSlotsInHalfFrame()
  {
  	uint8_t nr=0;
  	uint8_t i;
  	
  	for(i=0; i<(inf.frame/2); i++)
  	{
  		if(reservedSlot[i]==TRUE)
  		{
  			nr++;
  		}
  	}
  	
  	return nr;
  }*/
    event void SimpleTime.sigtdmatimecoming(){
   
   } 
                                                   
                                                                                                                                                     
}


