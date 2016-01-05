/* $Id: LinkEstimatorP.nc,v 1.17 2010-06-29 22:07:50 scipio Exp $ */
/*
 * Copyright (c) 2006 University of Southern California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/*
 @ author Omprakash Gnawali
 @ Created: April 24, 2006
 */

#include "LinkEstimator.h"
#include "Lab.h"
module LinkEstimatorP {
  provides {
    interface StdControl;
    interface AMSend as Send;
    interface Receive;
    interface LinkEstimator;
    interface Init;
    interface Packet;
    //interface CompareBit;
  }

  uses {
    interface AMSend;
    interface AMPacket as SubAMPacket;
    interface Packet as SubPacket;
    interface Receive as SubReceive;
    interface LinkPacketMetadata;
    interface Random;
  }
}

implementation {

  // configure the link estimator and some constants
  enum {
    // If the eetx estimate is below this threshold
    // do not evict a link
    EVICT_EETX_THRESHOLD = 55,
    // maximum link update rounds before we expire the link
    MAX_AGE = 6,
    // if received sequence number if larger than the last sequence
    // number by this gap, we reinitialize the link
    MAX_PKT_GAP = 10,
    BEST_EETX = 0,
    INVALID_RVAL = 0xff,
    INVALID_NEIGHBOR_ADDR = 0xff,
    // if we don't know the link quality, we need to return a value so
    // large that it will not be used to form paths
    VERY_LARGE_EETX_VALUE = 0xff,
    // decay the link estimate using this alpha
    // we use a denominator of 10, so this corresponds to 0.2
    ALPHA = 9,
    // number of packets to wait before computing a new
    // DLQ (Data-driven Link Quality)
    DLQ_PKT_WINDOW = 5,
    // number of beacons to wait before computing a new
    // BLQ (Beacon-driven Link Quality)
    BLQ_PKT_WINDOW = 3,
    // largest EETX value that we feed into the link quality EWMA
    // a value of 60 corresponds to having to make six transmissions
    // to successfully receive one acknowledgement
    LARGE_EETX_VALUE = 60
  };

  // keep information about links from the neighbors
  neighbor_table_entry_t NeighborTable[NEIGHBOR_TABLE_SIZE];
  // link estimation sequence, increment every time a beacon is sent
  uint8_t linkEstSeq = 0;
  // if there is not enough room in the packet to put all the neighbor table
  // entries, in order to do round robin we need to remember which entry
  // we sent in the last beacon
  uint8_t prevSentIdx = 0;
  //记录上一次发linkquality时候发到第几个了
  uint8_t prevSentlinkqualityIdx = 0;
  // get the link estimation header in the packet
  linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, sizeof(linkest_header_t));
  }
	

/*
 command void* Packet.getPayload(message_t* msg, uint8_t len) {
   //这里返回了一个len + sizeof(linkest_header_t) 大小的payload
   //并且返回的指针变量是正好超过了linkest_header_t
    void* payload = call SubPacket.getPayload(msg, len +  sizeof(linkest_header_t));
    if (payload != NULL) {
      payload += sizeof(linkest_header_t);
    }
    return payload;
  }
*/




  // get the link estimation footer (neighbor entries) in the packet
  linkest_footer_t* getFooter(message_t* ONE m, uint8_t len) {
    // To get a footer at offset "len", the payload must be len + sizeof large.
    //beaconMsg 是一个ctp_routing_header_t* beaconMsg;
    //len=sizeof(ctp_routing_header_t)
    //这个len 是在
    //返回一个在len处的指针len + (uint8_t *)call Packet.getPayload(m,len + sizeof(linkest_footer_t))
    //Packet.getPayload返回已在msg初始的地方的大小至少为len+sizeof 的指针

    //Packet.getPayload(m,len + sizeof(linkest_footer_t) 
    //这里返回了一个len + sizeof(linkest_header_t) 大小的payload
   //并且返回的指针变量是正好超过了linkest_header_t
   //这里又加了个len所以正好指导了footer的位置
    return (linkest_footer_t* ONE)(len + (uint8_t *)call Packet.getPayload(m,len + sizeof(linkest_footer_t)));
  }

  // add the link estimation header (seq no) and link estimation
  // footer (neighbor entries) in the packet. Call just before sending
  // the packet.

  uint8_t addLinkEstHeaderAndFooter(message_t * ONE msg, uint8_t len) {
   /*****我自己从前面搞的BeaconSend.send(AM_BROADCAST_ADDR, 
                                    &beaconMsgBuffer, 
                                    sizeof(ctp_routing_header_t));
	len = 	sizeof(ctp_routing_header_t) */
    uint8_t newlen;
    linkest_header_t *hdr;
    linkest_footer_t *footer;
    uint8_t i, j, k;
    uint8_t maxEntries, newPrevSentIdx;
    dbg("LI", "newlen1 = %d\n", len);
    hdr = getHeader(msg);
    /* linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, sizeof(linkest_header_t));
  }*/
    footer = getFooter(msg, len);
	/*beaconMsg = call BeaconSend.getPayload(&beaconMsgBuffer, call BeaconSend.maxPayloadLength());
		
	// 返回了一个把linkest_herder_t这么大的值丢掉在前面，指向后面的指针，所以在linkestimator里面getheader没有产生冲突
		command void* Packet.getPayload(message_t* msg, uint8_t len) {
		 void* payload = call SubPacket.getPayload(msg, len +  sizeof(linkest_header_t));
		if (payload != NULL) {
		payload += sizeof(linkest_header_t);
		}
		 return payload;
		  }
	//返回了一个减去linkest_header_t长度的maxpayloadlength()
		command uint8_t Packet.maxPayloadLength() {
	 return call SubPacket.maxPayloadLength() - sizeof(linkest_header_t);
	}*/
    maxEntries = ((call SubPacket.maxPayloadLength() - len - sizeof(linkest_header_t))
		  / sizeof(linkest_footer_t));

    // Depending on the number of bits used to store the number
    // of entries, we can encode up to NUM_ENTRIES_FLAG using those bits
    if (maxEntries > NUM_ENTRIES_FLAG) {
    //NUM_ENTRIES_FLAG = 15 最多允许15个footer
      maxEntries = NUM_ENTRIES_FLAG;
    }
    dbg("LI", "Max payload is: %d, maxEntries is: %d\n", call SubPacket.maxPayloadLength(), maxEntries);

    j = 0;
    newPrevSentIdx = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE && j < maxEntries; i++) {
    //#define NEIGHBOR_TABLE_SIZE 10 最多允许10个neighbor在周围
      uint8_t neighborCount;
      neighbor_stat_entry_t * COUNT(neighborCount) neighborLists;
      //安全处理，使得neighborlist 这个指针指向neighborcount个变量
      if(maxEntries <= NEIGHBOR_TABLE_SIZE)
        neighborCount = maxEntries;
	//最大允许的footer数量小于neighbor的数量
      else
        //最大允许的footer数量大于neighbor的数量
        neighborCount = NEIGHBOR_TABLE_SIZE;
      
      neighborLists = TCAST(neighbor_stat_entry_t * COUNT(neighborCount), footer->neighborList);
      /*> This is a C trick that allows you to address that region of the
	> payload as an array even though you don't know apriori how many
	> elements you have.*/
	//使neighborList这个变量指向 footer所指的neighorlist
	//uint8_t prevSentIdx = 0;以前sent的index指向
      k = (prevSentIdx + i + 1) % NEIGHBOR_TABLE_SIZE;
      //循环的在这个NeighborTable里面的值放到footer里面发出去
      //假如说以前是prevSentIdx=3现在加上i+1就是下一个应该放进去的值
       // ***我自己从前面搞的 keep information about links from the neighbors
      // ****我自己从前面搞的 neighbor_table_entry_t NeighborTable[NEIGHBOR_TABLE_SIZE];
      if ((NeighborTable[k].flags & VALID_ENTRY) &&
	  (NeighborTable[k].flags & MATURE_ENTRY)) {
	neighborLists[j].ll_addr = NeighborTable[k].ll_addr;
	neighborLists[j].inquality = NeighborTable[k].inquality;
	newPrevSentIdx = k;
	dbg("LI", "Loaded on footer: %d %d %d\n", j, neighborLists[j].ll_addr,
	    neighborLists[j].inquality);
	j++;
      }
    }
    prevSentIdx = newPrevSentIdx;
    // link estimation sequence, increment every time a beacon is sent
    //uint8_t linkEstSeq = 0;
    hdr->seq = linkEstSeq++;
    hdr->flags = 0;
    // use last four bits to keep track of
    // how many footer entries there are
    //***我自己从前面搞的NUM_ENTRIES_FLAG = 15, 15换算成二进制1111&j就是得出了多少个entries再和flagsbit 或就好了
    hdr->flags |= (NUM_ENTRIES_FLAG & j);
    //把新的length传回去加上了linkestimation的头和尾
    newlen = sizeof(linkest_header_t) + len + j*sizeof(linkest_footer_t);
    dbg("LI", "newlen2 = %d\n", newlen);
    return newlen;
  }


  // initialize the given entry in the table for neighbor ll_addr
  //把指定的NeighborTable i的地方设置为地址ll_addr 并初始化
  void initNeighborIdx(uint8_t i, am_addr_t ll_addr) {
    neighbor_table_entry_t *ne;
    ne = &NeighborTable[i];
    ne->ll_addr = ll_addr;
    ne->lastseq = 0;
    ne->rcvcnt = 0;
    ne->failcnt = 0;
    ne->flags = (INIT_ENTRY | VALID_ENTRY);
    ne->inage = MAX_AGE;
    ne->outage = MAX_AGE;
    ne->inquality = 0;
    ne->outquality = 0;
    ne->eetx = 0;
  }

  // find the index to the entry for neighbor ll_addr
  //在NeighborTable里面找到地址为ll_addr 返回i值 没找到返回 INVALID_RVAL
  uint8_t findIdx(am_addr_t ll_addr) {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
	if (NeighborTable[i].ll_addr == ll_addr) {
	  return i;
	}
      }
    }
    return INVALID_RVAL;
  }

  // find an empty slot in the neighbor table
  //在NeighborTable里面找到一个没有用到的地方，然后看他是否可以进去，行返回i值，不行返回return INVALID_RVAL;
  //用neightable的flags的最低位判断是否可以进入
  uint8_t findEmptyNeighborIdx() {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
      } else {
	return i;
      }
    }
      return INVALID_RVAL;
  }

  // find the index to the worst neighbor if the eetx
  // estimate is greater than the given threshold
  //遍历NeighborTable[i] 找到个最差的neighboridx，然后再和thresholdEETX比较，然后返回
  uint8_t findWorstNeighborIdx(uint8_t thresholdEETX) {
    uint8_t i, worstNeighborIdx;
    uint16_t worstEETX, thisEETX;

    worstNeighborIdx = INVALID_RVAL;
    worstEETX = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (!(NeighborTable[i].flags & VALID_ENTRY)) {
	dbg("LI", "Invalid so continuing\n");
	continue;
      }
      if (!(NeighborTable[i].flags & MATURE_ENTRY)) {
	dbg("LI", "Not mature, so continuing\n");
	continue;
      }
      if (NeighborTable[i].flags & PINNED_ENTRY) {
	dbg("LI", "Pinned entry, so continuing\n");
	continue;
      }
      thisEETX = NeighborTable[i].eetx;
      if (thisEETX >= worstEETX) {
	worstNeighborIdx = i;
	worstEETX = thisEETX;
      }
    }
    if (worstEETX >= thresholdEETX) {
      return worstNeighborIdx;
    } else {
      return INVALID_RVAL;
    }
  }

  // update the quality of the link link: self->neighbor
  // this is found in the entries in the footer of incoming message
  //找到neighbor这个值，然后更新自己到他的链路质量
  void updateReverseQuality(am_addr_t neighbor, uint8_t outquality) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx != INVALID_RVAL) {
      NeighborTable[idx].outquality = outquality;
      NeighborTable[idx].outage = MAX_AGE;
    }
  }

  // update the EETX estimator
  // called when new beacon estimate is done
  // also called when new DEETX estimate is done
  //做一个以前的值，加上新的值，来估计eetx
  void updateEETX(neighbor_table_entry_t *ne, uint16_t newEst) {
    ne->eetx = (ALPHA * ne->eetx + (10 - ALPHA) * newEst + 5)/10;
  }


  // update data driven EETX
  //跟新data driven的EETX 如果说没有成功传输的，就是传输的失败的次数
  //否则(10 * ne->data_total) / ne->data_success - 10;
  //****不太理解？失败的除以总共的？-10？
  void updateDEETX(neighbor_table_entry_t *ne) {
    uint16_t estETX;

    if (ne->data_success == 0) {
      // if there were no successful packet transmission in the
      // last window, our current estimate is the number of failed
      // transmissions
      estETX = (ne->data_total - 1)* 10;
    } else {
      estETX = (10 * ne->data_total) / ne->data_success - 10;
      ne->data_success = 0;
      ne->data_total = 0;
    }
    updateEETX(ne, estETX);
  }


  // EETX (Extra Expected number of Transmission)
  // EETX = ETX - 1
  // computeEETX returns EETX*10
  //计算EETX
  uint8_t computeEETX(uint8_t q1) {
    uint16_t q;
    if (q1 > 0) {
      q =  2550 / q1 - 10;
      /*q=2550/255*packet recieve rate(PRR) -10
	q= 10(1/prr -1)
	----->prr= 10/(10+q) 这里的q是eetx
	所以如果q（eetx）是10的话，说明prr的概率是50%
	说明需要重传一次包才行


	*/
      if (q > 255) {
	q = VERY_LARGE_EETX_VALUE;
      }
      return (uint8_t)q;
    } else {
      return VERY_LARGE_EETX_VALUE;
    }
  }

  // BidirETX = 1 / (q1*q2)
  // BidirEETX = BidirETX - 1
  // computeBidirEETX return BidirEETX*10
  //计算双边的EETX，说明在ucalgary_2012_rafieikarkvandi_hamid的第87页
  uint8_t computeBidirEETX(uint8_t q1, uint8_t q2) {
    uint16_t q;
    if ((q1 > 0) && (q2 > 0)) {
      q =  65025u / q1;
      //因为前面q1和q2都乘以了个255，所以现在要在分子加个65025=255*255
      q = (10*q) / q2 - 10;
      if (q > 255) {
	q = LARGE_EETX_VALUE;
      }
      return (uint8_t)q;
    } else {
      return LARGE_EETX_VALUE;
    }
  }

  // update the inbound link quality by
  // munging receive, fail count since last update
  //跟新NeighborTable的表linkestimation
  void updateNeighborTableEst(am_addr_t n) {
    uint8_t i, totalPkt;
    neighbor_table_entry_t *ne;
    uint8_t newEst;
    uint8_t minPkt;
 //minPkt 值是
    minPkt = BLQ_PKT_WINDOW;
    //要等minPkt更新一次Link Quality
    // number of beacons to wait before computing a new
    // BLQ (Beacon-driven Link Quality)
    // BLQ_PKT_WINDOW = 3,
    dbg("LI", "%s\n", __FUNCTION__);
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->ll_addr == n) {
      //遍历的表是要找的addresss
	if (ne->flags & VALID_ENTRY) {
	//进来是有效的
	  if (ne->inage > 0)
	  //进来的age--了
	    ne->inage--;
	  if (ne->outage > 0)
	  //出去的age--
	    ne->outage--;
	  
	  if ((ne->inage == 0) && (ne->outage == 0)) {
	    ne->flags ^= VALID_ENTRY;//和1亦或，把flags这个东西关掉，变成0
	    ne->inquality = ne->outquality = 0;//把这个inquality和outquality变成0
	  } else {//如果inage和outage不同时为零的话
	    dbg("LI", "Making link: %d mature\n", i);
	    ne->flags |= MATURE_ENTRY;//把flags和mature_entry或，变成‘成熟’状态
	    totalPkt = ne->rcvcnt + ne->failcnt;//计算总共的paktet数
	    dbg("LI", "MinPkt: %d, totalPkt: %d\n", minPkt, totalPkt);
	    if (totalPkt < minPkt) {
	    //如果总共的paket数小于最小跟新的数目，总共的paket数等于最小要更新的数目
	      totalPkt = minPkt;
	    }
	    //如果总共进来的packet等于0那么。。。不可能这个情况LOL，除非minPkt=0
	    if (totalPkt == 0) {
	      ne->inquality = (ALPHA * ne->inquality) / 10;
	    } else {
	      newEst = (255 * ne->rcvcnt) / totalPkt;
	      /*****************************************
	      这里就是丢包率映射到了一个255的值，刚好那1byte可以装下
	       间接反映了丢包率，又方便了传输。
	      ******************************/
	      //转换成小于255的一个值，接受的包/总共的包
	      dbg("LI,LITest", "  %hu: %hhu -> %hhu", ne->ll_addr, ne->inquality, (ALPHA * ne->inquality + (10-ALPHA) * newEst + 5)/10);
	      ne->inquality = (ALPHA * ne->inquality + (10-ALPHA) * newEst + 5)/10;
	      //更新inquality的值
	    }
	    ne->rcvcnt = 0;
	    ne->failcnt = 0;
	    //更新完后重置
	  }
	  updateEETX(ne, computeBidirEETX(ne->inquality, ne->outquality));
	  //计算两个方向的EETX值，然后用来更新eetx
	}
	else {
	  dbg("LI", " - entry %i is invalid.\n", (int)i);
	}
      }
    }
  }


  // we received seq from the neighbor in idx
  // update the last seen seq, receive and fail count
  // refresh the age
  //当我们收到来自neighbor的消息是，我们更新last seen seq, receive and fail count，并且更新age
  void updateNeighborEntryIdx(uint8_t idx, uint8_t seq) {
    uint8_t packetGap;

    if (NeighborTable[idx].flags & INIT_ENTRY) {
      dbg("LI", "Init entry update\n");
      NeighborTable[idx].lastseq = seq;
      NeighborTable[idx].flags &= ~INIT_ENTRY;
    }
    
    packetGap = seq - NeighborTable[idx].lastseq;
    dbg("LI", "updateNeighborEntryIdx: prevseq %d, curseq %d, gap %d\n",
	NeighborTable[idx].lastseq, seq, packetGap);
    NeighborTable[idx].lastseq = seq;
    NeighborTable[idx].rcvcnt++;
    //更新了进来的年纪
    NeighborTable[idx].inage = MAX_AGE;
    if (packetGap > 0) {
      NeighborTable[idx].failcnt += packetGap - 1;
    }
    if (packetGap > MAX_PKT_GAP) {
      NeighborTable[idx].failcnt = 0;
      NeighborTable[idx].rcvcnt = 1;
      NeighborTable[idx].outage = 0;
      NeighborTable[idx].outquality = 0;
      NeighborTable[idx].inquality = 0;
    }
    //计算packetgap 更新了这个neighbortable[idx]的值，当接收到超过三个的值，更新linkestimation的值
    if (NeighborTable[idx].rcvcnt >= BLQ_PKT_WINDOW) {
      updateNeighborTableEst(NeighborTable[idx].ll_addr);
    }

  }



  // print the neighbor table. for debugging.
  //打印我这个节点存储的neighbor table 里面所有的信息
  void print_neighbor_table() {
    uint8_t i;
    neighbor_table_entry_t *ne;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->flags & VALID_ENTRY) {
	dbg("LI,LITest", "%d:%d inQ=%d, inA=%d, outQ=%d, outA=%d, rcv=%d, fail=%d, biQ=%d\n",
	    i, ne->ll_addr, ne->inquality, ne->inage, ne->outquality, ne->outage,
	    ne->rcvcnt, ne->failcnt, computeBidirEETX(ne->inquality, ne->outquality));
      }
    }
  }

  // print the packet. for debugging.
  //打印这个包里的信息
  void print_packet(message_t* msg, uint8_t len) {
    uint8_t i;
    uint8_t* b;

    b = (uint8_t *)msg->data;
    for(i=0; i<len; i++)
      dbg_clear("LI", "%x ", b[i]);
    dbg_clear("LI", "\n");
  }

  // initialize the neighbor table in the very beginning
  //把neighbortable给刷新好
  void initNeighborTable() {
    uint8_t i;

    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      NeighborTable[i].flags = 0;
    }
  }

  command error_t StdControl.start() {
    dbg("LI", "Link estimator start\n");
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

  // initialize the link estimator
  //启动了把initnetighortable刷新好
  command error_t Init.init() {
    dbg("LI", "Link estimator init\n");
    initNeighborTable();
    return SUCCESS;
  }

  // return bi-directional link quality to the neighbor
  command uint16_t LinkEstimator.getLinkQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return VERY_LARGE_EETX_VALUE;
    } else {
      if (NeighborTable[idx].flags & MATURE_ENTRY) {
	return NeighborTable[idx].eetx;
      } else {
	return VERY_LARGE_EETX_VALUE;
      }
    }
  }

  // return the quality of the link: neighor->self
  command uint16_t LinkEstimator.getReverseQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return VERY_LARGE_EETX_VALUE;
    } else {
      if (NeighborTable[idx].flags & MATURE_ENTRY) {
	return computeEETX(NeighborTable[idx].inquality);
      } else {
	return VERY_LARGE_EETX_VALUE;
      }
    }
  }

  // return the quality of the link: self->neighbor
  command uint16_t LinkEstimator.getForwardQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return VERY_LARGE_EETX_VALUE;
    } else {
      if (NeighborTable[idx].flags & MATURE_ENTRY) {
	return computeEETX(NeighborTable[idx].outquality);
      } else {
	return VERY_LARGE_EETX_VALUE;
      }
    }
  }

  // insert the neighbor at any cost (if there is a room for it)
  // even if eviction of a perfectly fine neighbor is called for
  command error_t LinkEstimator.insertNeighbor(am_addr_t neighbor) {
    uint8_t nidx;
    //如果本来有了，不用加
    nidx = findIdx(neighbor);
    if (nidx != INVALID_RVAL) {
      dbg("LI", "insert: Found the entry, no need to insert\n");
      return SUCCESS;
    }
    //如果还有空位，加进去
    nidx = findEmptyNeighborIdx();
    if (nidx != INVALID_RVAL) {
      dbg("LI", "insert: inserted into the empty slot\n");
      initNeighborIdx(nidx, neighbor);
      return SUCCESS;
    } else {
    //找一个最差的踢出来
      nidx = findWorstNeighborIdx(BEST_EETX);
      if (nidx != INVALID_RVAL) {
	dbg("LI", "insert: inserted by replacing an entry for neighbor: %d\n",
	    NeighborTable[nidx].ll_addr);
	signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
	initNeighborIdx(nidx, neighbor);
	return SUCCESS;
      }
    }
    return FAIL;
  }

  // pin a neighbor so that it does not get evicted
  command error_t LinkEstimator.pinNeighbor(am_addr_t neighbor) {
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    NeighborTable[nidx].flags |= PINNED_ENTRY;
    return SUCCESS;
  }

  // pin a neighbor so that it can get evicted
  command error_t LinkEstimator.unpinNeighbor(am_addr_t neighbor) {
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    NeighborTable[nidx].flags &= ~PINNED_ENTRY;
    return SUCCESS;
  }


  // called when an acknowledgement is received; sign of a successful
  // data transmission; to update forward link quality
  //收到了ACK做的事情，我这里没有用ACK
  command error_t LinkEstimator.txAck(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    ne = &NeighborTable[nidx];
    ne->data_success++;
    ne->data_total++;
    if (ne->data_total >= DLQ_PKT_WINDOW) {
      updateDEETX(ne);
    }
    return SUCCESS;
  }

  // called when an acknowledgement is not received; could be due to
  // data pkt or acknowledgement loss; to update forward link quality
  //没收到ACK，更新data eetx
  //暂时不理解，不管他
  command error_t LinkEstimator.txNoAck(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }

    ne = &NeighborTable[nidx];
    ne->data_total++;
    if (ne->data_total >= DLQ_PKT_WINDOW) {
      updateDEETX(ne);
    }
    return SUCCESS;
  }

  // called when the parent changes; clear state about data-driven link quality
  command error_t LinkEstimator.clearDLQ(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    ne = &NeighborTable[nidx];
    ne->data_total = 0;
    ne->data_success = 0;
    return SUCCESS;
  }
  //计算LinkEstimator.Loadestimation 需要运行多少次才能把链路消息装载完毕
  //这里的len = sizeof(link_header),用来区分是哪一个节点的链路质量信息
  command uint8_t LinkEstimator.Gettimes(message_t* msg, uint8_t len){
	uint8_t maxEntries = 0;
	uint8_t maturecount = 0;
	uint8_t i = 0;
	//计算还要传几次才能把linkestimation 的值传干净的变量
	uint8_t times_left =0;
	
	for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++){
		 if ((NeighborTable[i].flags & VALID_ENTRY) &&
		  (NeighborTable[i].flags & MATURE_ENTRY))
		  {maturecount++;}
		}
	maxEntries = ((call SubPacket.maxPayloadLength() - len)/ sizeof(linkest_footer_t));
	//这里要用maturecount/maxEntries向上取整
	//如果正好maturecount是maxentries的倍数，maturecount/maxEntries 。

	dbg("lab", "maturecount: %d maxEntries:%d \n", maturecount, maxEntries);
	times_left = maturecount/maxEntries;
	if((times_left * maxEntries) == maturecount){
		times_left = times_left;
	}
	else{ times_left = times_left + 1;}
	return times_left;
  }

   linkest_footer_t* getlinkqualityFooter(message_t* ONE m, uint8_t len) {
    return (linkest_footer_t* ONE)(len + (uint8_t *)call SubPacket.getPayload(m,len + sizeof(linkest_footer_t)));
  }
  //这里真正的packet是 SubAMPacket
  //准备改上面的，返回一个指向这里的指针
  //*****************************
  //     ^
  // len |
  //这里的len = sizeof(link_header),用来区分是哪一个节点的链路质量信息
  //复用LinkEstimator.h里面的linkest_footer_t和neighbor_stat_entry_t
  //只不过这里的neighbor_stat_entry_t里面的nx_uint8_t inquality存的是outbound quality 即me->neibor 的quality
  //newlength 是用来存放加载之后的长度
  //传回消息新的长度
  command uint8_t LinkEstimator.Loadestimation(message_t* msg, uint8_t len){
	  linkest_footer_t *footer;
	  uint8_t i, j, k;
	  //uint8_t maturecount;
          uint8_t maxEntries, newPrevSentIdx;
	  uint8_t newlength;
	  link_header_t *link_header;
	  //指针获取完毕，准备加载链路信息；
	  footer = getlinkqualityFooter(msg, len);
	  maxEntries = ((call SubPacket.maxPayloadLength() - len)/ sizeof(linkest_footer_t));
          /*********************************************************************
	  这里最多有10个邻居，所以如果是邻居超过多少个，我要重传几次。确保能传完。
	  **********************************************************************/
	  //头的大小2 footer的大小是3byte packet最大长度是28byte，我一次最多能传8footer个
	  //这里我最多支持10个neighbor，所以两次能传完
	  dbg("LI", "Max payload is: %d, maxEntries is: %d\n", call SubPacket.maxPayloadLength(), maxEntries);
	  j = 0;
	  //用于判断有多少个成熟了
	 // maturecount = 0;
          newPrevSentIdx = 0;
	/*  for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++){
		 if ((NeighborTable[i].flags & VALID_ENTRY) &&
		  (NeighborTable[i].flags & MATURE_ENTRY))
		  {maturecount++;}
	  }*/

	  for (i = 0; i < NEIGHBOR_TABLE_SIZE && j < maxEntries; i++){
		 uint8_t neighborCount;
		 neighbor_stat_entry_t * COUNT(neighborCount) neighborLists;
		 if(maxEntries <= NEIGHBOR_TABLE_SIZE)
			neighborCount = maxEntries;
			//最大允许的footer数量小于neighbor的数量
		 else
			 //最大允许的footer数量大于neighbor的数量
		     neighborCount = NEIGHBOR_TABLE_SIZE;
	  
		 neighborLists = TCAST(neighbor_stat_entry_t * COUNT(neighborCount), footer->neighborList);
		 k = (prevSentlinkqualityIdx + i + 1) % NEIGHBOR_TABLE_SIZE;

		 if ((NeighborTable[k].flags & VALID_ENTRY) &&
		  (NeighborTable[k].flags & MATURE_ENTRY)) {
			neighborLists[j].ll_addr = NeighborTable[k].ll_addr;
			//复用LinkEstimator.h里面的linkest_footer_t和neighbor_stat_entry_t
			//这个inquality存的是从自己->邻居的链路状态
			//return computeEETX(NeighborTable[idx].outquality)
			neighborLists[j].inquality = NeighborTable[k].outquality;
			newPrevSentIdx = k;
			dbg("lab", "Loaded on footer: %d %d %d\n", j, neighborLists[j].ll_addr,
			 neighborLists[j].inquality);
			j++;
			}
	  }
	  prevSentlinkqualityIdx = newPrevSentIdx;
	  //在这里要把link_header_t 这个里面加上有多少个footer的信息
	  //hdr->flags |= (NUM_ENTRIES_FLAG & j);
	  link_header = call SubPacket.getPayload(msg, sizeof(link_header_t));
	  link_header -> flags |= (NUM_ENTRIES_FLAG & j);
	  newlength =len + j*sizeof(linkest_footer_t);
	  return newlength;
	  //怎么判断传完了没有呢？
	  //如果说成熟的个数大于最大传输个数那么说明要传两次才能传完 return FAIL;
	  //如果是小于等于，说明可以传完了 return SUCCESS;
	  //if(maturecount <= maxEntries){return SUCCESS;}
	  //else {return FAIL;} 
  }


  // user of link estimator calls send here
  // slap the header and footer before sending the message
 // beaconMsg = call BeaconSend.getPayload(&beaconMsgBuffer, call BeaconSend.maxPayloadLength());
 //在加上这个头的时候，BeaconSend.maxPayloadLength 把前面的linkst header给减掉了。
 //
  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    uint8_t newlen;
    /*****我自己从前面搞的BeaconSend.send(AM_BROADCAST_ADDR, 
                                    &beaconMsgBuffer, 
                                    sizeof(ctp_routing_header_t));
	len = 	sizeof(ctp_routing_header_t) */
    newlen = addLinkEstHeaderAndFooter(msg, len);
    //把新的length传回去加上了linkestimation的头和尾
    //newlen = sizeof(linkest_header_t) + len + j*sizeof(linkest_footer_t);
    dbg("LITest", "%s packet of length %hhu became %hhu\n", __FUNCTION__, len, newlen);
    dbg("LI", "Sending seq: %d\n", linkEstSeq);
    print_packet(msg, newlen);
    return call AMSend.send(addr, msg, newlen);
  }

  // done sending the message that originated by
  // the user of this component
  event void AMSend.sendDone(message_t* msg, error_t error ) {
    return signal Send.sendDone(msg, error);
  }

  // cascade the calls down
  command uint8_t Send.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  // called when link estimator generator packet or
  // packets from upper layer that are wired to pass through
  // link estimator is received
  void processReceivedMessage(message_t* ONE msg, void* COUNT_NOK(len) payload, uint8_t len) {
    uint8_t nidx;
    uint8_t num_entries;

    dbg("LI", "LI receiving packet, buf addr: %x\n", payload);
    print_packet(msg, len);

    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
	//如果接收到了广播的信息
      linkest_header_t* hdr = getHeader(msg);
      linkest_footer_t* ONE footer;
      am_addr_t ll_addr;
      //得到消息源
      ll_addr = call SubAMPacket.source(msg);

      dbg("LI", "Got seq: %d from link: %d\n", hdr->seq, ll_addr);
      //计算出有多少个entries
      num_entries = hdr->flags & NUM_ENTRIES_FLAG;
      
      print_neighbor_table();

      // update neighbor table with this information
      // find the neighbor
      // if found
      //   update the entry
      // else
      //   find an empty entry
      //   if found
      //     initialize the entry
      //   else
      //     find a bad neighbor to be evicted
      //     if found
      //       evict the neighbor and init the entry
      //     else
      //       we can not accommodate this neighbor in the table
      //这里在判断收到的这个信息源在不在我的neighbor table里，能不能放下
      nidx = findIdx(ll_addr);
      if (nidx != INVALID_RVAL) {
	dbg("LI", "Found the entry so updating\n");
	//是早就有的就跟新neighbor的entry, neighbor的entry里面有值可以，超过最小beacon的时候会自己更新channel quality
	updateNeighborEntryIdx(nidx, hdr->seq);
      } else {
	nidx = findEmptyNeighborIdx();
	if (nidx != INVALID_RVAL) {
	  dbg("LI", "Found an empty entry\n");
	  initNeighborIdx(nidx, ll_addr);
	  updateNeighborEntryIdx(nidx, hdr->seq);
	} else {
	  nidx = findWorstNeighborIdx(EVICT_EETX_THRESHOLD);
	  if (nidx != INVALID_RVAL) {
	    dbg("lab", "12345671#!@#!@#!@#7Evicted neighbor %d at idx %d\n",
		NeighborTable[nidx].ll_addr, nidx);
	    signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
	    initNeighborIdx(nidx, ll_addr);
	  } else {
	    dbg("lab", "!@#!@#$@#$!@#!@No room in the table\n");
	  }
	}
      }


      /* Graphical explanation of how we get to the head of the
       * footer in the following code 
       * <---------------------- payloadLen ------------------->
       * -------------------------------------------------------
       * linkest_header_t  | payload  | linkest_footer_t* ...|
       * -------------------------------------------------------
       * ^                              ^                      ^
       * |                              |                      |
       * subpayload                     |                      payloadEnd
       *                                |
       *                                payloadEnd - footersize*num footers
      */
	//如果nidx成功被加入进去了，且footer里面的num_entries>0的
      if ((nidx != INVALID_RVAL) && (num_entries > 0)) {
	uint8_t payloadLen = call SubPacket.payloadLength(msg);
	void* COUNT_NOK(payloadLen) subPayload = call SubPacket.getPayload(msg, payloadLen);
	void* payloadEnd = subPayload + payloadLen;
	dbg("LI", "Number of footer entries: %d\n", num_entries);
	//计算出了footer在哪里，只能指向num_entries多个，这是一个安全模式
	footer = TCAST(linkest_footer_t* COUNT(num_entries), (payloadEnd - (num_entries*sizeof(linkest_footer_t))));
	{
	  uint8_t i;
	  am_addr_t my_ll_addr;
          neighbor_stat_entry_t * COUNT(num_entries) neighborLists;
	  my_ll_addr = call SubAMPacket.address();
          neighborLists = TCAST(neighbor_stat_entry_t * COUNT(num_entries), footer->neighborList);
	  for (i = 0; i < num_entries; i++) {
	    dbg("LI", "%d %d %d\n", i, neighborLists[i].ll_addr,
	    	neighborLists[i].inquality);
	    if (neighborLists[i].ll_addr == my_ll_addr) {
	      updateReverseQuality(ll_addr, neighborLists[i].inquality);
	      //别人的inquality就是我的outquality
	    }
	  }
	}
      }
      print_neighbor_table();
    }


  }

  // new messages are received here
  // update the neighbor table with the header
  // and footer in the message
  // then signal the user of this component
  event message_t* SubReceive.receive(message_t* msg,
				      void* payload,
				      uint8_t len) {
    dbg("LI", "Received upper packet. Will signal up\n");
    processReceivedMessage(msg, payload, len);
    return signal Receive.receive(msg,
				  call Packet.getPayload(msg, call Packet.payloadLength(msg)),
				  call Packet.payloadLength(msg));
  }

  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }

  // subtract the space occupied by the link estimation
  // header and footer from the incoming payload size
  command uint8_t Packet.payloadLength(message_t* msg) {
    linkest_header_t *hdr;
    hdr = getHeader(msg);
    return call SubPacket.payloadLength(msg)
      - sizeof(linkest_header_t)
      - sizeof(linkest_footer_t)*(NUM_ENTRIES_FLAG & hdr->flags);
  }

  // account for the space used by header and footer
  // while setting the payload length
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    linkest_header_t *hdr;
    hdr = getHeader(msg);
    call SubPacket.setPayloadLength(msg,
				    len
				    + sizeof(linkest_header_t)
				    + sizeof(linkest_footer_t)*(NUM_ENTRIES_FLAG & hdr->flags));
  }
  //把用来链路估计得头减掉了
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(linkest_header_t);
  }

  // application payload pointer is just past the link estimation header
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
   //这里返回了一个len + sizeof(linkest_header_t) 大小的payload
   //并且返回的指针变量是正好超过了linkest_header_t
    void* payload = call SubPacket.getPayload(msg, len +  sizeof(linkest_header_t));
    if (payload != NULL) {
      payload += sizeof(linkest_header_t);
    }
    return payload;
  }
}

