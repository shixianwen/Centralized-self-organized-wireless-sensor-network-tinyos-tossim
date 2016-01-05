#include "LinkEstimator.h"
#include "Lab.h"
#include "TestSerial.h"
/*#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct radio_type_msg {//此信息是放在beacon中实现的，通过beacon来交换信息
  nx_uint8_t messagetype;//等于1代表是广播我等级是多少的消息
  nx_uint8_t node_level;//放在包头用来表示该节点的等级
} radio_type_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

typedef struct {
  am_addr_t parent;
  uint8_t parent_level;

} route_info_t;

//下面这个结构体用来传输，放到消息的头里面
typedef struct {
//messagetype等于2说明是用来传播链路质量用的
//**************************************************
//这个里面应该还要加一个Numberof entries of footer
  am_addr_t myaddress;
  uint8_t messagetype;
  uint8_t flags;


} link_header_t;

#endif
*/

module labC @safe() {
    uses {
	interface Boot;
	interface AMSend as BeaconSend;
        interface Receive as BeaconReceive;//这个是wire到linkestimator上的
        interface LinkEstimator;
	interface Packet;
	interface AMPacket;//这个是wire到activemessageC上面去的
	interface SplitControl as AMControl;
	//interface Timer<TMilli> as BeaconTimer;
	interface Random;

	interface PacketAcknowledgements;

	interface AMSend as QualitySend;

	interface Receive as QualityRecieve;
	interface Timer<TMilli> as QualityTimer;
	interface Timer<TMilli> as FowarderTimer;

	interface Timer<TMilli> as RadioTimer;//如果我收到searial 发过来的信息，我的radio还在发送，则等一段时间再发送


	interface Queue<message_forward_t*> as SendQueue;
	//interface Pool<message_forward_t> as MessageFowarderPool;
	interface Pool<message_forward_t> as MessageSendPool;//用来作为发送pool，如果还没有收到ACK的话要存着，收到ACK的再删掉
	interface Pool<message_t> as MessageRecievePool;//用来作为接收pool,转发的消息存到MessageSendPool转发给自己的母亲，
	//再从MessageRecievePool给一个新的消息空间来收信息，如果还没有收到ACK先存着MessageRecievePool和MessageSendPool的消息，
	//收到了的再删掉再把这两个空间都释放。

	//这一块用来做serial sender
	interface AMSend as SerialSend;
	interface Receive as SerialReceive;
	interface SplitControl as Control;//这里用来做serialcontrol,记得开哦。
	interface AMSend as RelaySend;//think_node用来传递download的路由信息用的
	interface Receive as RelayReceive;
	//要做一个basestation那样的think_node
	//根据收到的包的myaddress及所要到达节点的地方，根据relayinfo里面的路由信息，传到下一个节点
	//收到下一个节点发送ACK，删除消息
	//下一个节点收到后，判断是不是自己的，myaddress = node id 如果是，跟新自己的信息
	//如果不是，去relayinfo里面继续找，重复上面的步骤


	//以下开始写TDMA以及各种时隙的处理
	interface TDMA;
	interface EASAP;
	interface EASAPImp;
	interface SimpleTime;
	interface SplitControl as TDMAControl;
	interface Timer<TMilli> as DelayTimer;

	//以下对schedule，信息回传测试处理
	//interface Timer<TMilli> as ScheduleTimer;
	interface AMSend as FinalTestSend;
	interface Receive as FinalTestRecieve;

	interface Timer<TMilli> as Quality_send_retransmit_csma;
	interface Timer<TMilli> as Quality_forward_retransmit_csma;
    }
}
    implementation{
	//用来做最后回传message的测试信息定义在此
	uint32_t seq = 0;//用来分辨现在是传的第多少条信息了
	bool is_scheduled = FALSE;//用来判断是否接受到了路由信息，如果接收到了就要完成接收的任务
	bool is_trigerred = FALSE;//用来控制是否开始最后的信息测试，两个条件被trigger，一个是ScheduleTimer fired了
				  //另一个是is_scheduled变成true，且被它的儿子发送了测试信息过来trigger了
				  //如果is_scheduled是false但是被儿子triger了，报错！
	bool My_test_msg_need_retrasmit = FALSE; //如果说这次自己的MSG信息没传成功，下个时刻接着传
	 message_t  radioQueueBufs1[RADIO_QUEUE_LEN];//buffer
	 message_t  * ONE_NOK radioQueue1[RADIO_QUEUE_LEN];
	 uint8_t    radioIn1, radioOut1;   //？？？？
	 bool       radioFull1;//radio状态，

	//TDMA所需要的变量定义在此
	tSlot cSlot;
	uint8_t pocet_odeslanych;
	uint32_t remSlotsTime;
	uint32_t maxSend = 0;
	tSlot rand_slot = 0;//一开始用来做beacon estimation的，记录下来，后面用来删除用
	tTime cas1;            
	tTime cas2;
	//当quality timer启动时就不发送beacon了
	bool quality_time_start = FALSE;
	uint32_t tdmastarttime = 98000000;
	bool firstserialmessage = TRUE;//第一个来的serial message 加上450000为tdmastart的参考时间
				       //这个用来判断是不是第一个，第一个结束就给它设置成false
	bool starttest = FALSE;//用来判断可不可以开始测试
	bool onlystartonce = TRUE;
	//我这里需要两个queue
	//串口设置
	//现在的程序暂时不需要
	message_t  uartQueueBufs[UART_QUEUE_LEN];//数据Buffer
	message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN]; 
	uint8_t    uartIn, uartOut;
	bool       uartBusy, uartFull;//串口状态

	//这里有负责radio的queue,能不能和上面的pool复用起来，算了还是自己定义一个新的和往上传的数据对应
	 message_t  radioQueueBufs[UART_RADIO_LEN];//buffer
	 message_t  * ONE_NOK radioQueue[UART_RADIO_LEN];
	 uint8_t    radioIn, radioOut;   //？？？？
	 bool       radioFull;//radio状态，
	 bool is_busy = FALSE;
	//用来作为往thinknode发最终的testmsg用的
	message_t testMsgBuffer;
        message_t beaconMsgBuffer;
	//底下这个暂时没有其它用，就是用来在
	//times_left = call LinkEstimator.Gettimes(&qualityMsgBuffer, sizeof(link_header));
	//中计算下还需要多少次才能装下
	message_t qualityMsgBuffer;
	//用来储存relay需要用的节点信息
	//qualitytimer如果发生重传的话，不能马上重传，需要用qualitysend_retransmit和qualityforward_retransmit将其保存起来
	//像csma那样随机等待时间在传送

	message_t qualitysend_retransmit;
	message_t qualityforward_retransmit;
	uint8_t qualitysendlength = 0;
	uint8_t qualityforwardlength = 0;

	struct relayinginfo relayinfo;
	uint8_t relayreccount = 0; 

	radio_type_msg_t *beaconMsg;
	link_header_t *link_header;//用来传播信息的时候把我的地址和msgtype放在里面
	bool is_think_node = FALSE;
	
	bool my_levelchanged = FALSE;
	bool QualityTimer_is_from_task = FALSE;
	bool From_SendQuality_task = FALSE;
	bool From_ForwardQuality_task = FALSE;
	bool From_finaltestMymessageSend = FALSE;
	bool From_sendtest_relay_Task = FALSE;
	bool only_send_one_my_msg = FALSE;
	//如果说来了比我等级低的节点的信息，我把我的母亲节点设置成它，并且把
	//my_level_changed 变成true。这样防止下次收到信息的时候改变母亲节点
	uint8_t times_left = 0;
	uint8_t my_level = 10;	
	//用来判断节点的等级，来实现第一次的routing
	route_info_t route_info;//用来储存节点的母亲的地址和等级

	message_forward_t * ONE_NOK qe;//这个用来指向qualitysend的message_forward_t的从MessageSendPool拿来的变量

	//这样send会出问题，应该用pool来解决这个问题，来处理这个连续收发的问题
	//ack了再把这个
	uint8_t newlength = 0;
	uint8_t testframenumber = TEST_FRAME_NUMBER;
	 linkest_footer_t* getlinkqualityFooter(message_t* ONE m, uint8_t len) {
		 return (linkest_footer_t* ONE)(len + (uint8_t *)call Packet.getPayload(m,len + sizeof(linkest_footer_t)));
		  }

	//定义一个用来debug的footer值
	//msg是用来放用LinkEstimator.Loadestimation处理过的指针的
	//len是sizeof(link_header_t) 需要把头的消息给弄掉
	//不知道为什么用uint8_t payloadLen = call Packet.payloadLength(msg); 返回的值是0
	void print_footer_table(message_t* msg, uint8_t number_footers){
		linkest_footer_t* ONE footer;
		if(number_footers > 0){
			//uint8_t payloadLen = call Packet.payloadLength(msg);	
			//void* COUNT_NOK(payloadLen) subPayload = call Packet.getPayload(msg, payloadLen);
			//void* payloadEnd = subPayload + payloadLen;
			//dbg("lab","payloadlen %d\n", call Packet.payloadLength(msg));
			//footer = TCAST(linkest_footer_t* COUNT(number_footers), (payloadEnd - (number_footers*sizeof(linkest_footer_t))));
			  footer = getlinkqualityFooter(msg,sizeof(link_header_t)) ;
			{
				uint8_t i;
				neighbor_stat_entry_t * COUNT(number_footers) neighborLists;
				neighborLists = TCAST(neighbor_stat_entry_t * COUNT(number_footers), footer->neighborList);
				for (i = 0; i < number_footers; i++) {
					dbg("lab1", "%d %d %d\n", i, neighborLists[i].ll_addr, neighborLists[i].inquality);
				}
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
		dbg_clear("lab", "%x ", b[i]);
		dbg_clear("lab", "\n");
	   }
	 //这个task处理被triggered以后往母亲节点发信息。
	//应该在isownslot里面post
	//如果是判断没有需要relay的信息之后就post这个直接发，不需要存
	//总之不管是不是成功发送了此次的信息
	//如果有relay的信息就发relay的信息，如果没有relay的信息，seqnumber不变，接着发。
	task void finaltestMymessageSend(){
		//message_t testMsgBuffer;
		test_type_msg_t *finaltestmsg;
		//如果没有过schedule timer 的时间，或者自己已经schedule好，但是没有收到过下面节点的信息。
		if(is_trigerred == FALSE){
			dbg("lab","NOT TRIGGERED!FALSE!\n");
			return;
		}
		if(is_busy){
			dbg("lab","current radio busy final test\n");
			return;
		}
		finaltestmsg = (test_type_msg_t*)call Packet.getPayload(&testMsgBuffer, call Packet.maxPayloadLength());
		finaltestmsg->my_address = TOS_NODE_ID;
		if(My_test_msg_need_retrasmit){
			dbg("lab","in retransmit current seq number is %d\n",seq-1);
			finaltestmsg->seq = seq-1;}
		else{	
			dbg("lab","in retransmit current seq number is %d\n",seq);
			finaltestmsg->seq = seq;
			seq++;
		}
		
		dbg("lab", "finaltestMymessageSend: %s\n", sim_time_string());
		//将代表msg=1及用来宣布等级的beacon发送出去，并且将我的等级放在里面。
		call PacketAcknowledgements.requestAck(&testMsgBuffer);
		From_finaltestMymessageSend= TRUE;
		if(call FinalTestSend.send(route_info.parent, &testMsgBuffer, sizeof(test_type_msg_t)) == SUCCESS){
		 is_busy = TRUE;
		}
		
	}
	//当一个节点被trigger之后
	//这个task判断是send我自己的还是别人的
	//如果有别人的就一直发别人的，如果没有了，就发自己的,有且仅发一条。
	//发自己的就post finaltestMymessageSend();就行了
	task void sendtest_relay_Task(){
		// uint8_t len;
		 message_t* msg;
		if(is_trigerred == FALSE){
			dbg("lab"," in task sendtest_relay_Task() NOT TRIGGERED!FALSE!\n");
			return;
		}

		if (is_busy) {
		  //不太可能现在会忙
		  dbg("lab","sendtest message FLAUT!!!Current Radio is busy\n");
		  return;
		  }
		  //发完了（不属于满的情况）
		  atomic
		  if (radioIn1 == radioOut1 && !radioFull1){
			  //radioIn1 == radioOut1是空或者满的情况
			  //radiofull1假是不满，真是满
			  //这里说明！radiofull1是假的情况进入，则是不满的情况。
			  //则说明，此时没有其他消息
			  //队列是空的，没有转发，则发自己的消息
			  //发自己的消息只能发一次*********
			  dbg("lab1","queue empty, send my message only_send_one_my_msg is %d\n",only_send_one_my_msg);
			  //这里判断以前是否进去过，因为只能发一条消息。
			  //only_send_one_my_msg变成true的条件
			  //发过我的一条且仅有一条信息，且发成功了。if(！only_send_one_my_msg)
			  if(!only_send_one_my_msg){
				post finaltestMymessageSend();
			  }
			  return;
			}

		 msg = radioQueue1[radioOut1];
		 //len = call Packet.payloadLength(msg);
		 //这个消息需要被ack；
		 call PacketAcknowledgements.requestAck(msg);
		 From_sendtest_relay_Task = TRUE;
		 if (call FinalTestSend.send(route_info.parent, msg, sizeof(test_type_msg_t)) == SUCCESS){
			 is_busy = TRUE;
			 dbg("lab1","FinalTestSend been successfully send\n");
			}
		
	}
	event void FinalTestSend.sendDone(message_t* msg, error_t error){
		if(!is_busy){
			dbg("lab","sth wrong in FinalTestSend\n");
			return;
		}
		
		if(From_finaltestMymessageSend&&From_sendtest_relay_Task){
			dbg("lab","sth wrong in FinalTestSend both From_finaltestMymessageSend&&From_sendtest_relay_Task = true \n");
		}

		//如果是从From_finaltestMymessageSend来的话 是自己的信息
		if((call PacketAcknowledgements.wasAcked(msg))&&(From_finaltestMymessageSend)){
			dbg("lab1","successfully send in FinalTestSend From_finaltestMymessageSend \n");
			is_busy = FALSE;
			My_test_msg_need_retrasmit = FALSE;
			From_finaltestMymessageSend = FALSE;
			//是自己的信息且成功了，以后再也不发了。
			only_send_one_my_msg = TRUE;
			return;
		}
		else if((!call PacketAcknowledgements.wasAcked(msg))&&(From_finaltestMymessageSend)){
			//在下一个可用的时隙再次发送自己本条消息
			is_busy = FALSE;
			My_test_msg_need_retrasmit = TRUE;
			From_finaltestMymessageSend = FALSE;
			dbg("lab1","From_finaltestMymessageSend RETRANSMIT THIS MSG AT NEXT AVAIABLE SLOT\n");
			return;
		}
		//如果是从from_sendtest_relay_Task来的且ack了 是转发的信息
		else if((call PacketAcknowledgements.wasAcked(msg))&& (From_sendtest_relay_Task)){
			dbg("lab1","successfully send in FinalTestSend From_sendtest_relay_Task\n");
			is_busy = FALSE;
			From_sendtest_relay_Task = FALSE;
			//回收信息处理
			atomic
				if (msg == radioQueue1[radioOut1])
				{
					if (++radioOut1 >= RADIO_QUEUE_LEN)
					radioOut1 = 0;
				        if (radioFull1)
					radioFull1 = FALSE;
				}
		}
		//如果是从from_sendtest_relay_Task来没有ack了
		else if((!call PacketAcknowledgements.wasAcked(msg))&& (From_sendtest_relay_Task)){
			//radioOut1这个指针不变，下个slot再发的时候还是原来的指针不变
			dbg("lab1","From_sendtest_relay_TaskRETRANSMIT THIS MSG AT NEXT AVAIABLE SLOT\n");
			is_busy = FALSE;
			From_sendtest_relay_Task = FALSE;
		}
	}
	task void FowardQualityTask(){
		//这个任务主要是用来实现把收到的别的节点的包，转发给母亲节点
		//是busy的话让FowarderTimer startoneshot {里面有post FowardQualityTask}
		//先判断SendQueue是不是为空
		//是空的返回，不是空的的话，就把队首的指针拿出来，指针指向MessageSendPool
		//这个MessageSendPool消息转发给母亲，这个消息需要被ACK
		//sendone 里面被ACK了就回收MessageSendPool
		//没有的话继续发，直到被ack了为止
		message_forward_t* ONE_NOK queue;
		if(is_busy){
			dbg("lab","current radio is busy. Fowardtimer fired 100000later\n");
			call FowarderTimer.startOneShot(1000+call Random.rand16()%6000);
			return;
		}
		if(call SendQueue.empty()){
			dbg("lab","The queque is empty i have nothing to send\n");
			return;
		}
		else{
			queue = call SendQueue.head();
			call PacketAcknowledgements.requestAck(&(queue->message));
			//*******要求是queue的长度，怎么记下来
			if(call QualitySend.send(route_info.parent, &(queue->message), queue->payloadlength) != SUCCESS)
			{dbg("lab","something is wrong in the send of FowardQualityTask\n");
			 return;
			}
			else{is_busy = TRUE;From_ForwardQuality_task = TRUE;} 
		}
	}
	

	task void sendQualityTask(){
		
		
		//做一个指针行指向message_t的变量
		
		//message_forward_t* ONE_NOK queue;
		if(is_busy){
			dbg("lab1","current radio is busy. Quality timer fired 100000later\n");
			QualityTimer_is_from_task = TRUE;
			call QualityTimer.startOneShot(1000+call Random.rand16()%6000);
			return;
		}
		//首先判断pool是不是满了
		dbg("lab1","MessageSendPool's size is %d \nMessageSendPool.maxSize is %d\n",call MessageSendPool.size(),call MessageSendPool.maxSize());
		if(call MessageSendPool.size() == 0)
		{	
			dbg("lab","the currentpool is full\n");
			QualityTimer_is_from_task = TRUE;
			call QualityTimer.startOneShot(1000+call Random.rand16()%6000);
			return;
		}

		//返回了一个指针，和它相等，所以不用加星号
		qe = call MessageSendPool.get(); 
		
		
		link_header = call Packet.getPayload(&(qe->message), sizeof(link_header_t));
		link_header->myaddress = TOS_NODE_ID;
		if(times_left == 1){
		    link_header->messagetype = 1;
		}
		else{
		link_header->messagetype = times_left;
		}
		link_header->flags = 0;
		//开始用command error_t Loadestimation(message_t* msg, uint8_t len) 加装outbound quality +地址 信息
		newlength = call LinkEstimator.Loadestimation(&(qe->message), sizeof(link_header));

		//****************************************************
		//我现在debug想再这里把qe这个消息打印出来怎么打印？
		//链路估计信息成功消息装载完毕，现在检验重传部分和大网络部分是否成功
		//首先需要检验重传部分是否成功
		dbg("lab","the number of footer is %d\n", link_header->flags & NUM_ENTRIES_FLAG);

		print_footer_table(&(qe->message),(link_header->flags & NUM_ENTRIES_FLAG));
		
		print_packet(&(qe->message), newlength);
		dbg("lab1","newlength%d\n", newlength);
		//把我的quality信息往我的母亲发,先前要求这条信息ack
		call PacketAcknowledgements.requestAck(&(qe->message));
		if(call QualitySend.send(route_info.parent, &(qe->message), newlength) == SUCCESS){
			is_busy = TRUE;
			From_SendQuality_task = TRUE;
		}

		//计算还剩多少次，只剩下0次就不post自己了	
		times_left--;
		if(times_left>0)
		{post sendQualityTask();}
		else{
		//所有链路估计消息都发完了。就把QualityTimer_is_from_task设置成false了
		QualityTimer_is_from_task = FALSE;
		}
	}
	event void Quality_send_retransmit_csma.fired(){
				dbg("lab","@@@@@@@@quality send retransmit length is %d", qualitysendlength );
				call PacketAcknowledgements.requestAck(&qualitysend_retransmit);
				if(call QualitySend.send(route_info.parent, &qualitysend_retransmit, qualitysendlength) != SUCCESS)
				{dbg("lab","something is wrong in the Msg retransmit\n");}
	}
	event void Quality_forward_retransmit_csma.fired(){
				dbg("lab","@@@@@quality send retransmit length is %d", qualityforwardlength );
				call PacketAcknowledgements.requestAck(&qualityforward_retransmit);
				if(call QualitySend.send(route_info.parent, &qualityforward_retransmit, qualityforwardlength) != SUCCESS)
				{dbg("lab","something is wrong in the Msg retransmit\n");}
	}
	event void QualitySend.sendDone(message_t* msg, error_t error){
		uint8_t payloadLen = call Packet.payloadLength(msg);
		dbg("lab1","From_SendQuality_task == %x and From_ForwardQuality_task == %x\n" ,From_SendQuality_task,From_ForwardQuality_task);
		if (!is_busy) {
		  //something smells bad around here
		  return;
		}
		if((From_SendQuality_task == TRUE)&&(From_ForwardQuality_task == TRUE))
		{
			dbg("lab","Wrong Both the From_SendQuality_task == TRUE and From_ForwardQuality_task == TRUE\n");
			return;
		}


		if((From_SendQuality_task == TRUE) &&(From_ForwardQuality_task == FALSE)){
			if(call PacketAcknowledgements.wasAcked(msg)){
				dbg("lab","the link quality message have been succesfully sent\n");
				//接下来要对这个msg做回收处理
				if(call MessageSendPool.put(qe) == SUCCESS)
				{	
					dbg("lab1","SendQuality_task this msg have been succeefully recycled\n");
				}
				else {
					dbg("lab","something is wrong on in the MessageSendPool\n");
				}
			is_busy = FALSE;
			From_SendQuality_task = FALSE;
			dbg("lab","**END From_SendQuality_task == %x and From_ForwardQuality_task == %x\n" ,From_SendQuality_task,From_ForwardQuality_task);
			return;
			}
			else{	
				//message_t qualitysend_retransmit;
				//message_t qualityforward_retransmit;
				//dbg("lab","the link quality need to be retransmitted\n");
				
				
				//if(call QualitySend.send(route_info.parent, msg, newlength) != SUCCESS)
				
				uint16_t timedelay = 0;
				uint8_t i = 0;
				uint8_t* b;
				b = (uint8_t *)msg->data;
				dbg("lab","\nthe packet need to be retransmitted my mother node is %d\n mymother level is %d",route_info.parent,route_info.parent_level);
				for(i = 0; i<payloadLen; i++){
					qualitysend_retransmit.data[i] = b[i];
					dbg("lab","%x",qualitysend_retransmit.data[i]);
				}
				qualitysendlength = payloadLen;

				dbg("lab","\nthe saved retrasmited message are there\n");
				//这里将重传信息保存起来了
				//写两个时钟，随机时间fired之后，再尝试重新发送
				timedelay = 2000+call Random.rand16()%20000;
				dbg("lab","qualityresend time delay is %d\n",timedelay);
				call Quality_send_retransmit_csma.startOneShot(timedelay);
				dbg("lab","collision I need rest for a while\n");
				//call PacketAcknowledgements.requestAck(msg);
				//if(call QualitySend.send(route_info.parent, msg, call Packet.payloadLength(msg)) != SUCCESS)
				//{dbg("lab","something is wrong in the Msg retransmit\n");}
				return;
				//*****************************************************************这里要做重传处理
			 }
		}
		else if((From_ForwardQuality_task == TRUE)&&(From_SendQuality_task == FALSE))
		{
			if(call PacketAcknowledgements.wasAcked(msg)){
				dbg("lab","the Forward quality message have been succesfully sent\n");
			
				//对此条msg的MessageSendPool空间做回收处理
				if(call MessageSendPool.put(call SendQueue.dequeue()) == SUCCESS)
					{	
						dbg("lab1","From_ForwardQuality this msg have been succeefully recycled\n");
					}
					else {
						dbg("lab","something is wrong on in the MessageSendPool\n");
					}
	
					is_busy = FALSE;
					From_ForwardQuality_task = FALSE;
					//这里再检查看看发送队列是不是为空的，不空的话再post forwardquality_task;
					if(!(call SendQueue.empty())){
						post FowardQualityTask();
					}
					dbg("lab","**END From_ForwardQuality == %x and From_ForwardQuality_task == %x\n" ,From_SendQuality_task,From_ForwardQuality_task);
					return;
			}
			else{	
				//和上面一样的处理
				uint16_t timedelay = 0;
				uint8_t i = 0;
				uint8_t* b;
				b = (uint8_t *)msg->data;
				
				dbg("lab","the Forward quality need to be retransmitted my mother node is %d mymother level is %d\n \n",route_info.parent,route_info.parent_level);
				for(i = 0; i<payloadLen; i++){
					qualityforward_retransmit.data[i] = b[i];
					dbg("lab","%x",qualityforward_retransmit.data[i]);
				}
				qualityforwardlength = payloadLen;
				dbg("lab","\nthe saved retrasmited message are there\n");
				timedelay = 2000+call Random.rand16()%20000;
				dbg("lab","qualityreforward time delay is %d\n",timedelay);
				call Quality_forward_retransmit_csma.startOneShot(timedelay);
				dbg("lab","collision I need rest for a while\n");
				//call PacketAcknowledgements.requestAck(msg);
				//if(call QualitySend.send(route_info.parent, msg, call Packet.payloadLength(msg)) != SUCCESS)
				//{dbg("lab","something is wrong in the Msg retransmit\n");}
				return;
				//*****************************************************************这里要做重传处理
			 }
		}
	}

	task void sendBeaconTask(){
		if(is_busy)
		{return;}
		//把用来链路估计得头减掉了
		//如果是用来写，getpayload需要最大的长度，如果是用来读，只需要弄成payload的长度就好了
		beaconMsg = call BeaconSend.getPayload(&beaconMsgBuffer, call BeaconSend.maxPayloadLength());
		beaconMsg->messagetype = 1;
		beaconMsg->node_level = my_level;
		dbg("lab1", "Beacontask %s\n", sim_time_string());
		//将代表msg=1及用来宣布等级的beacon发送出去，并且将我的等级放在里面。
		if(call BeaconSend.send(AM_BROADCAST_ADDR, 
                                    &beaconMsgBuffer, 
                                    sizeof(radio_type_msg_t)) == SUCCESS){
		 is_busy = TRUE;
		}
		else
		{
			dbg("lab","Fail to send the becon message\n");
		}
	}


	
	/*void print_packet(message_t* msg, uint8_t len) {
		uint8_t i;
		uint8_t* b;
	        b = (uint8_t *)msg->data;
		for(i=0; i<len; i++)
		dbg_clear("lab", "%x ", b[i]);
		dbg_clear("lab", "\n");
	   }*/
	   void print_packet_into_file(message_t* msg, uint8_t len) {
		uint8_t i;
		uint8_t* b;
	        b = (uint8_t *)msg->data;
		for(i=0; i<len; i++)
		dbg_clear("file", "%x ", b[i]);
		dbg_clear("file", "\n");
	   }
	   
	   //把整个链表打出来，用来做debug用,先把节点5的表打出来
	   void print_delay_info(){
		struct relayinginfo* pCurrent = & relayinfo;
		dbg("lablab","\n\n\n\n\nnew table begin");
		while(pCurrent != NULL){
			if(is_think_node){
				dbg("lablab","from %d,destination%d\n",pCurrent->relay, pCurrent->destination);
			}
			pCurrent = pCurrent-> next;
		}
		return;
	   }


	    //这个函数用来处理所有接收到的要转发的信息。
	    //先要判断from和linkheader->myaddress 有没有在这个链表里存在过
	    //如果存在过就不理他
	    //如果没有存在过，就加上这条转发信息
	   //struct relayinginfo relayinfo;
	   void process_relay_info(am_addr_t from,link_header_t* relayheader){
		//先做一个指向relayinfo的指针
		struct relayinginfo* pCurrent = & relayinfo;
		//初始化，第一个
		if((pCurrent->relay == TOS_NODE_ID) && (pCurrent->destination == TOS_NODE_ID)){
			pCurrent->relay = from;
			pCurrent->destination = relayheader->myaddress;
		}
		//遍历整个转发表，看看有没有重复的
		while(pCurrent != NULL){
			if ((pCurrent->relay == from)&&(pCurrent->destination == relayheader->myaddress)){
				//早就存了这条转发信息，不需要再存
				return;
			}
			pCurrent = pCurrent-> next;
		}
		//找到了都没有重复的
		//重新赋值
		pCurrent = & relayinfo;
		//找到最后一个relayinfo
		while(pCurrent->next != NULL){
			pCurrent = pCurrent->next;
		}
		//分配一个新的地址
		pCurrent->next = malloc(sizeof(struct relayinginfo));
		if (pCurrent->next == NULL){dbg("lab","Out of memory happened\n");}
		//make sure
		pCurrent->next->next = NULL;

		pCurrent->next->relay = from;
		
		pCurrent->next->destination = relayheader->myaddress;
		pCurrent->next->prev = pCurrent;
		dbg("lab","from %d,destination%d\n",pCurrent->next->relay, pCurrent->next->destination);
	   }
	event message_t* QualityRecieve.receive(message_t* msg, void* payload, uint8_t len){			
			am_addr_t from;			
			//用来保存转发信息的
			link_header_t* relayheader = (link_header_t*)call Packet.getPayload(msg, sizeof(link_header_t));
			from = call AMPacket.source(msg);
			dbg("lab","QualityRecieve.receive happened\n");
			process_relay_info(from,relayheader);
			print_delay_info();
		if(!is_think_node){
			uint8_t i = 0;
			uint8_t payloadLen = call Packet.payloadLength(msg);
			message_t * recycle; 
			uint8_t* b;
			message_forward_t * ONE_NOK qr;//这个用来指向QualityRecieve的message_forward_t的从MessageFowarderPool拿来的变量
		        b = (uint8_t *)msg->data;
			if(call MessageSendPool.size() == 0){
				dbg("lab","MessageFowarderPool is full\n");
				//我把MessageSendPool is full 设置的大一点，不要产生这种情况
			}
			else{	
				//所以定义一个message_forward_t的queque吧,到时候转发的时候发队列头的信息
				//发完之后回收MessageFowarderPool的资源
				/*
				qr是指向typedef struct {
					message_t message;
					uint8_t payloadlength;
					} message_forward_t;
					的指针
				*/
				//我给
				qr = call MessageSendPool.get();
				qr->payloadlength = payloadLen;
				dbg("lab","the message need forwader is as follows\n");
				for(i = 0; i<payloadLen; i++){
				//这样传有问题,我想把msg的data的值复制到到qr指向的message里面的payload里面
					(qr->message).data[i] = b[i];
					dbg("lab","%x",(qr->message).data[i]);
					//dbg("lab","%x",b[i]);
				}
				dbg("lab","\n");
				call SendQueue.enqueue(qr);
				post FowardQualityTask();
			}
			//回收这个msg的资源
			//用recycle来保证下一个接受到的msg不是用的这次接收用的msg
			recycle = call MessageRecievePool.get();
			call MessageRecievePool.put(msg);
			return recycle;
			//return msg;

			
		}
		else if (is_think_node){
			print_packet(msg, len);
			print_packet_into_file(msg, len);
			return msg;
		}
	}
	event message_t* BeaconReceive.receive(message_t* msg, void* payload, uint8_t len){
		am_addr_t from;
		uint16_t  linkquality = 255;
		uint16_t  MymotherLinkquality = 255;//旧妈妈
		radio_type_msg_t * rcm = (radio_type_msg_t*) payload;

		if(len != sizeof (radio_type_msg_t))
		{	
			//这个packet不是由radio 的类型的
			return msg;
		}
		from = call AMPacket.source(msg);
		//返回的是eetx的值，这个值255说明链路很不好，越小越好，0是最好的
		linkquality = call LinkEstimator.getForwardQuality(from);//新妈妈的质量
		dbg("lab1","My linkQuality to %d is %d\n", from, linkquality);
		//现在开始处理收到的beacon里面含有等级的信息
		//如果我的等级还没有改变过 my_levelchanged = FALSE 并且我收到包的那个人的等级比我低
		//我把我的等级设置成它的等级+1，并且把我的母亲节点设置成它
		if(!my_levelchanged)
		{	
			
			if(my_level > rcm->node_level)
			{	
				my_levelchanged = TRUE;
				my_level = rcm->node_level+1;
				route_info.parent = from;
				route_info.parent_level = rcm-> node_level;
				dbg("lab","My level is %d my mother node is %d my mother level is %d\n", my_level, route_info.parent, route_info.parent_level);
			}
		}
		//如果我母亲的等级和现在收到的等级刚好相等且my_levelchaned是真的话，代表已经更新过母亲了
		if(((my_level-1) == (rcm -> node_level))&&(my_levelchanged == TRUE)){
			MymotherLinkquality = call LinkEstimator.getForwardQuality(route_info.parent);
			//我母亲的链路质量没有这个新来的好
			if(MymotherLinkquality > linkquality){
				dbg("lab","My original mother is %d it's linkquality is %d level is %d\n now my mother is %d,it's linkquality is %d level is %d\n",route_info.parent,MymotherLinkquality,route_info.parent_level,from,linkquality,rcm-> node_level);
				route_info.parent =from;
				
			}
		}
		if(((my_level-1)>(rcm -> node_level))&&((my_levelchanged == TRUE))){
			MymotherLinkquality = call LinkEstimator.getForwardQuality(route_info.parent);
			if((MymotherLinkquality>30)&&(linkquality<30))
			{	
				my_level = rcm->node_level+1;
				dbg("lab"," %@#$!@#!@#%&*%%^$ change level!!!My original mother is %d it's linkquality is %d level is %d\n now my newmother is %d,it's linkquality is %d level is %d\n",route_info.parent,MymotherLinkquality,route_info.parent_level,from,linkquality,rcm-> node_level);
				route_info.parent =from;
				route_info.parent_level = rcm-> node_level;

			}
		}
		//dbg("lab","My level is %d my mother node is %d my mother level is %d\n", my_level, route_info.parent, 	route_info.parent_level);
		return msg;
	}
	  //从relay_info里根据所要发送的节点
	  //找到我要发送的下一个节点的地址
	  am_addr_t get_relay_address(am_addr_t myaddress){
		//先做一个指向relayinfo的指针
		struct relayinginfo* pCurrent = & relayinfo;
		//遍历整个表，找匹配项
		while(pCurrent != NULL){
			if(pCurrent->destination == myaddress){
				return pCurrent->relay;//如果找到了我想去的地址，就把relay node的地址返回。
			}
			pCurrent = pCurrent-> next;
		}
		dbg("lab","cannot find a suitable relay node for this address\n");
		dbg("lab","the address that is myaddress %d\n",myaddress);
		return myaddress;

	  }
	  //将串口过来的数据用radio转发出去
	    task void radioSendTask() {
		 uint8_t len;
		 am_addr_t addr;
		 message_t* msg;
		 test_serial_msg_t* rcm;
		 if (is_busy) {
		  //如果现在radio在忙，过会再发
		  dbg("lab","Current Radio is busy\n");
		  call RadioTimer.startOneShot(2000+call Random.rand16()%5000);
		  return;
		}
		 //发完了或者radio满了
		 atomic
			if (radioIn == radioOut && !radioFull){
			  return;
			}
		
		 msg = radioQueue[radioOut];
		 rcm = (test_serial_msg_t*)call Packet.getPayload(msg, sizeof(test_serial_msg_t));
		 //如果是根节点的话要指明一个可以让节点们统一开始tdma的时间,开始的时间为第一个消息包进来的时间加上450000，然后再下一个为零slot的frame
		 //的时候开始
		 if(is_think_node){
			rcm->tdma_start_time = tdmastarttime;
		 }
		 len = call Packet.payloadLength(msg);
		 //addr 要开始判断relayinfo里面的信息，找到我下一个节点，返回的是我要发送的下一个节点的地址
		 addr = get_relay_address(rcm -> myaddress);
		 dbg("lab","\n*****next address is %d\n",addr);
		 //这个消息需要被ack；
		 call PacketAcknowledgements.requestAck(msg);
		 if (call RelaySend.send(addr, msg, len) == SUCCESS){
			 is_busy = TRUE;
			 dbg("lab1","serial message has been successfully send\n");
			}	 
           }

	  //收到了路由信息，如果是自己的，tos node id = rcm -> myaddress 
	  //跟新自己的存放节点的表格，如果不是则通过relay_info找到下一个节点再传
	  event message_t* RelayReceive.receive(message_t* msg, void* payload, uint8_t len){
		//这里我要复用上面那几个queque
		 message_t *ret = msg;
		 test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(msg, sizeof(test_serial_msg_t));
		 if (len != sizeof(test_serial_msg_t)) {return msg;}
		
		 if(rcm->myaddress == TOS_NODE_ID){
			 bool rand_same_assign = FALSE;
			 //如果分配的和随机获得的一样
			 int i =0;
			 struct Node *pCurrent = call EASAP.getINF();
			 struct Slot* pSlot;
			 //设置自己的simpletimeC 让它到时间了会signal一个信号来提醒自己
			 //然后再下一个新的frame开始的时候开始发一个包
			 call SimpleTime.set_tdmastarttime(rcm->tdma_start_time);
			 dbg("lab","\nrcm->tdma_start_time is %d\n",rcm->tdma_start_time);
			 dbg("lab","my simpletime is %d\n", call SimpleTime.get());
			//*** call ScheduleTimer.startOneShot(100000);
			 is_scheduled = TRUE;//这里用来判断是否schedule了，好进行测试，并且让schedule时钟等50000秒之后fire一下
			 dbg("lab","\nThe relayinfo suceessfully reach destination\n");
			 dbg_clear("filew","destination %d",TOS_NODE_ID);
			 dbg("lab","'%d','%d','%d','%d'",rcm->myaddress,rcm->motheraddress,rcm->length,rcm->framelenghth);
			 for(i=0;i<(rcm->length);i++){
				dbg("lab","'%d',", rcm->a[i]);
			 }
			 dbg("lab","\n");
			//则更新自己的时隙信息
			//******这里还缺方法，我觉得应该要把msg保存好，然后再跟新  or 直接跟新应该不会来不及吧****//
			//我选择直接处理！！！来得急！
			//放弃自己以前用来传送beacon的所有slot
			//call EASAP.releaseOwnedSlots();
			//这里把我用来发beacon message 的rand_slot丢掉
			route_info.parent = rcm->motheraddress;
			dbg("lab1","my parent address is %d\n",route_info.parent);
			
			//根据这个传来的信息加slot
			call EASAP.setFrame(rcm-> framelenghth);
			call TDMA.setFrame(rcm-> framelenghth);
			for(i=0;i<(rcm->length);i++){
				call EASAPImp.addSlot(rcm->a[i], pCurrent);
				if((rcm->a[i]) == rand_slot){
					rand_same_assign = TRUE;
					dbg("lab1","before happened rand_same_assign= %d \n",rand_same_assign);
					dbg("lab1","******^%#!@#!@assign the same happened\n");
				}
			}
			//随机得到的和分配的不一样且是第一次分配
			if((!rand_same_assign)&&(relayreccount == 0)){
			dbg("lab1","After happened rand_same_assign= %d \n",rand_same_assign);
			dbg("lab1","******^%#!@#!@relayrecount = %d\n",relayreccount);
			call EASAPImp.removeSlot(rand_slot,pCurrent);
			}
			relayreccount = relayreccount +1;
			return ret;
		 }


		 dbg("lab","\nRelay revieve happened\n");
		
		 //已经判定这个relay info 不是给我自己的，我需要转发
		 //将收到的消息放到radio queque里
		atomic
		  if (!radioFull){
			ret = radioQueue[radioIn];
			radioQueue[radioIn] = msg;
			if (++radioIn >= RADIO_QUEUE_LEN)
			radioIn = 0;
			//队伍满了
			if (radioIn == radioOut)
			radioFull = TRUE;
			if (!is_busy){
				  post radioSendTask();
			}
			else{
				call RadioTimer.startOneShot(2000+call Random.rand16()%2000);
			}
		  }
		else{dbg("lab","serial packet droped\n");
		     dbg_clear("filew","serial packet droped in relay receive %d\n",TOS_NODE_ID);
			}    
	         return ret;
			
	  }
	    
	   event void RelaySend.sendDone(message_t* msg, error_t error){
		if (!is_busy) {
	          dbg("lab","relaysend's is busy fault\n");
		  //something smells bad around here
		  return;
		}
		//前一条的msg已经被确认了
		if(call PacketAcknowledgements.wasAcked(msg)){
			//回收信息处理
			atomic
				if (msg == radioQueue[radioOut])
				{
					if (++radioOut >= RADIO_QUEUE_LEN)
					radioOut = 0;
				        if (radioFull)
					radioFull = FALSE;
				}
			//等一段时间再发比较好
			is_busy = FALSE;
			//判断还有没有消息要发，如果有，则启动radiotimer
			if(radioIn == radioOut){
				dbg("lab1","all of the relay message has been sent\n");
			}
			else{
			call RadioTimer.startOneShot(2000+call Random.rand16()%5000);
			}
		}
		//前一条的消息没有被确认需要重传
		else{	
			 am_addr_t addr;
			 test_serial_msg_t* rcm;
			 rcm = (test_serial_msg_t*)call Packet.getPayload(msg, sizeof(test_serial_msg_t));
			 addr = get_relay_address(rcm -> myaddress);
			//重传信息
			call PacketAcknowledgements.requestAck(msg);
			if (call RelaySend.send(addr, msg, call Packet.payloadLength(msg)) == SUCCESS){
			 dbg("lab1","serial message has been successfully send\n");
			}
		}
	   }
	//串口接收数据
	 event message_t *SerialReceive.receive(message_t *msg,void *payload,uint8_t len) {
		 message_t *ret = msg;
		 //串口接收到数据发送给radio
		dbg("lab1","serial recieve happened\n");
		atomic
		  if (!radioFull){
			ret = radioQueue[radioIn];
			radioQueue[radioIn] = msg;
			if (++radioIn >= RADIO_QUEUE_LEN)
			radioIn = 0;
			//队伍满了
			if (radioIn == radioOut)
			radioFull = TRUE;
                         //应该在包里告诉他们，他们的ScheduleTimer应该什么时候fire一下，
			 //然后再下一个新的frame开始的时候开始发一个包
			 //如果是最新接收到的第一个包，现在的时间加上450000的下一个frame的 0 slot为开始时间
			 //准备把这个比较的时候写在simpletime里面，如果相等就signal一个tdma可以开始的事件
			 if(firstserialmessage){
				tdmastarttime = call SimpleTime.get() + 600000;
				dbg("lab","tdma start time is %d\n",tdmastarttime);
				firstserialmessage = FALSE;
			 }
			 
			if (!is_busy){
				  post radioSendTask();
			}
			else{	
				dbg("lab","current radio is busy*********\n");
				call RadioTimer.startOneShot(200+call Random.rand16()%200);
			}
		  }
		else{dbg("lab","serial packet droped\n");
		     dbg_clear("filew","serial packet droped in serial recieve %d\n",TOS_NODE_ID);
		}    
	 return ret;
	}
	event void RadioTimer.fired()
	{
		post radioSendTask();
		dbg("lab", "RadioTimer fired at %s\n", sim_time_string());
	}
	
	//做struct relayinginfo relayinfo 的初始化
	void init(){
		uint8_t i;
		struct relayinginfo* pCurrent = &relayinfo;
		pCurrent->next = NULL;
		pCurrent->prev = NULL;
		pCurrent->relay = TOS_NODE_ID;
		pCurrent->destination = TOS_NODE_ID;		
		for (i = 0; i < UART_QUEUE_LEN; i++)
		    uartQueue[i] = &uartQueueBufs[i];  //将buffer中的每一个赋给指针
	        uartIn = uartOut = 0;   //输入输出都为0
                uartBusy = FALSE;      //串口不忙
                uartFull = TRUE;       //数据已满
		 //同理设置radio
		for (i = 0; i < RADIO_QUEUE_LEN; i++)
		 radioQueue[i] = &radioQueueBufs[i];
		 radioIn = radioOut = 0; 
		 radioFull = TRUE;
		 //对testmessage的radio进行设置
		for (i = 0; i < RADIO_QUEUE_LEN; i++)
		 radioQueue1[i] = &radioQueueBufs1[i];
		 radioIn1 = radioOut1 = 0; 
		 radioFull1 = TRUE;

		 is_busy = FALSE;
		 quality_time_start = FALSE;
		 seq = 0;//用来分辨现在是传的第多少条信息了
	         is_scheduled = FALSE;//用来判断是否接受到了路由信息，如果接收到了就要完成接收的任务
		 is_trigerred = FALSE;
		 My_test_msg_need_retrasmit = FALSE;
		 tdmastarttime = 98000000;
		 firstserialmessage = TRUE;
		 starttest = FALSE;
		 only_send_one_my_msg = FALSE;
		 relayreccount = 0;
		 onlystartonce = TRUE;
		 qualitysendlength = 0;
		 qualityforwardlength = 0;
		 testframenumber = TEST_FRAME_NUMBER;
	}
	bool CanSendAnotherData(){
		uint32_t lastSend = 0;
		pocet_odeslanych++;
		cas2 = call SimpleTime.get();
		lastSend = cas2 - cas1;
		if(lastSend>maxSend){
			maxSend = lastSend;
		}
	  
		remSlotsTime = remSlotsTime - lastSend;

  		if(remSlotsTime > maxSend){
  			cas1 = call SimpleTime.get();
	  		return TRUE;
	  	}
  	
  		return FALSE;
	}
	task void ownSlotHandler(){
		dbg("lab1", "owbslothandler fired at %s\n", sim_time_string());
		//当quality_time没有fired的时候就可以进去
		if(!quality_time_start){
		post sendBeaconTask();}
		//如果被trigger了，可以开始测试模式及往根节点发信息
		//且本身不是根节点
		//且到了下一个frame的开始时间
		dbg("lab1","in the slot handler only starttest equal %d\n",starttest);
		dbg("lab1","current slot is %d current logic time is %d\n",cSlot, call SimpleTime.get());
		if((is_trigerred)&&(!is_think_node)&&starttest){
		post sendtest_relay_Task();
		dbg("lab","current slot is %d current logic time is %d\n",cSlot, call SimpleTime.get());
		}
		
	}
	 /**
	 * Start delay timer
	 **/
	task void startDelayTimer(){
		call DelayTimer.startOneShot(TRANS_DELAY);  		
          }
	event void BeaconSend.sendDone(message_t* msg, error_t error){
		if ((msg != &beaconMsgBuffer) || !is_busy) {
		  //something smells bad around here
		  return;
		}
		if(CanSendAnotherData()){
		    post sendBeaconTask(); 
		}
		is_busy = FALSE;
	}

	event void DelayTimer.fired(){
		dbg("lab1", "delaytimer fired %s\n", sim_time_string());
		post ownSlotHandler();	
		return;
	   }
	event void TDMA.sigNewSlot(tSlot slot){
	 
	  cSlot = slot;
	  pocet_odeslanych = 0;
	  remSlotsTime = (uint32_t)call TDMA.getInterval();
          if(TOS_NODE_ID == 1)
	  dbg("lab1","SLOT NUMBER %d\n",cSlot);
	  cas1 = call SimpleTime.get();
	  //如果判断已经过了tdmastart时间，且刚好到了下一个帧的slot 0
	  //则可以开始发测试消息了
	  if(is_trigerred&&(cSlot == 0)){
		if(starttest && (testframenumber<=0)){
			onlystartonce = FALSE;
			starttest = FALSE;
			dbg("lab","only startonce equal %d\n",onlystartonce);
			dbg("lab","only starttest equal %d\n",starttest);
		}
		if(onlystartonce){
		starttest = TRUE;
		//every time a new frame coming, each node have another message to send
		only_send_one_my_msg =FALSE;
		//新的frame来临，清空finaltestbuffer所有信息
		//是空或者满的情况
		radioIn1 = radioOut1 = 0; 
		//不是满的情况，则整个是空的
		radioFull1 = FALSE;
		My_test_msg_need_retrasmit = FALSE;
		testframenumber = testframenumber-1;
		dbg("lab","There are %d frames left $!@$!@#!@#\n",testframenumber);
		dbg("lab","in the first time only starttest equal %d\n",starttest);
		}
		dbg("lab1","***starttest true begin to start test sim time%s\n",sim_time_string());
	  }
	  //是我自己的slot的话，我就发送beacon 用来估计信道
	  if(call EASAP.isOwnSlot(cSlot)){
		
		post startDelayTimer();  
	  dbg("lab1","**************My local time is  %d *************\n", cas1);
	  dbg("lab1","My sim time%s\n",sim_time_string());
	  //这里都已经判断这个slot是不是自己的slot了
	  //if((TOS_NODE_ID == 6)||(TOS_NODE_ID == 23)||(TOS_NODE_ID == 31)||(TOS_NODE_ID == 2))
		if(TOS_NODE_ID==6)
	  	dbg("lab","is %d my own slot %d ?\n", cSlot,call EASAP.isOwnSlot(cSlot));
	  }
	 
	}

	event void TDMAControl.startDone(error_t err){
		if(err == SUCCESS){
			struct Node *pCurrent = call EASAP.getINF();
			struct Slot *pSlot;
			//TDMA.start第一个参数没有用，设置不了时隙
			//我这里一开始默认frame的长度是32
			//然后随机给每个节点分配一个时隙用来发beacon signal
			//这样碰撞机会应该会很小了
			call TDMA.start(1, 100, DEFAULT_INTERVAL);//我占有了slot,每个frame 32个slot 1 1000ms
			//is_busy = FALSE;
			rand_slot = call Random.rand16()%100;
			call EASAPImp.addSlot(rand_slot, pCurrent);//给自己随机分配0到第31个时隙
			pSlot = pCurrent->slots;
			while (pSlot!= NULL){
				dbg("lab","My slot is %d *************\n", pSlot->slot);
				pSlot = pSlot->next;
			   }
		 }
		else{
			call TDMAControl.start();
		}
	}


	void print_packet_into_seq_file(message_t* msg, uint8_t len) {
		uint8_t i;
		uint8_t* b;
	        b = (uint8_t *)msg->data;
		for(i=0; i<len; i++)
		dbg_clear("seqfile", "%x ", b[i]);
		dbg_clear("seqfile", "\n");
	   }
	event message_t* FinalTestRecieve.receive(message_t* msg, void* payload, uint8_t len){
		message_t *ret = msg;
		test_type_msg_t* rcm = (test_type_msg_t*)call Packet.getPayload(msg, sizeof(test_type_msg_t));
		dbg("lab","\nenter FinalTestRecieve\n");
		if (len != sizeof(test_type_msg_t)) { dbg("lab1","\n have not pass test enter FinalTestRecieve\n"); return msg;}
		//是think_node，写入文件
		dbg("lab1","\npass test enter FinalTestRecieve\n");
		if(is_think_node){
			dbg("lab","\n****************************\n\n\n$@#$@!#!@#$ from%d,sequencenumber:%d\n**************************\n\n\n",rcm-> my_address,rcm->seq);
			print_packet_into_seq_file(msg,len);
			return ret;
		}
		/* message_t  radioQueueBufs1[RADIO_QUEUE_LEN];//buffer
		 message_t  * ONE_NOK radioQueue1[RADIO_QUEUE_LEN];
		uint8_t    radioIn1, radioOut1;   //？？？？
		bool       radioFull1;//radio状态，*/
		//转发给parent节点
		else{	

			//判断自己是不是schedule了
			//如果没有被scheduled，scheduletimmer需要增加等待时间，并报错
			if (!is_scheduled){
				 dbg("lab","\n no schedule need more scheduletime FLAUT!!!\n");
					return ret;
			}
			if(!is_trigerred){
				//没有同时被trigger,因为要到450000之后，然后到下一个frame的slot0之后才会被trigger.
				//所以有人提前开始了，是不被允许的
				dbg("lab","\n not triggered simutanious\n");
				return ret;
			}
			if(!starttest){

				//虽然已经被triggered了，但是这个还没有starttest
				//所以有人提前开始了，是不被允许的
				dbg("lab","\n not starttest do not enter next frame's slot 0\n");
				return ret;
			}
			dbg("lab1","\n****************************\n\n\nfrom%d,sequencenumber:%d\n**************************\n\n\n",rcm-> my_address,rcm->seq);
			 dbg("lab1","\n FinalTestRecieve revieve happened\n");
			atomic
			  if (!radioFull){
				ret = radioQueue1[radioIn1];
				radioQueue1[radioIn1] = msg;
				if (++radioIn1 >= RADIO_QUEUE_LEN)
				radioIn1 = 0;
				//队伍满了
				if (radioIn1 == radioOut1)
				radioFull1 = TRUE;
				//已经存好了，但是这里不能马上发
				//需要在tdma的地方才能发
			  }
			else{dbg("lab","FinalTestRecieve packet droped\n");
			     dbg_clear("filew","final test droped%d \n",TOS_NODE_ID);			    
				}    
			return ret;
					
		}

	}

	/*event void ScheduleTimer.fired(){
		is_trigerred = TRUE;
	}*/
	event void SimpleTime.sigtdmatimecoming(){
		is_trigerred = TRUE;
		dbg("lab1"," simple time tdma slot come, slots is triggered\n the current slot is %d\n",cSlot);
	}

	event void Boot.booted(){
		call AMControl.start();//开radio的listen
		call Control.start();//开serial的listen
		call TDMAControl.start();//开启tdma
		switch(TOS_NODE_ID)
		{
		    case 100: is_think_node = TRUE;break;
		    default: is_think_node = FALSE;
		}

		if(is_think_node)
		{
			my_level = 1;
		}

		else {my_level = 100;}
		dbg("lab","**************My level is %d *************\n", my_level);
		init();
	return;
	}
	 event void Control.startDone(error_t error) {
		  if (error == SUCCESS) {
			 uartFull = FALSE;  //启动成功，serial数据不满
		 }
	 }
	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			radioFull = FALSE;  //启动成功，radio数据不满
			radioFull1 = FALSE;  //启动成功，radio数据不满
			//call BeaconTimer.startPeriodic(1000);
			
			call QualityTimer.startOneShot(500000);
		}
	}

	event void FowarderTimer.fired()
	{
		post FowardQualityTask();
		dbg("lab", "FowarderTime fired at %s\n", sim_time_string());
	}
	event void QualityTimer.fired(){
		//这句话说QualityTimer.fired 这个任务不是从QualityTimer_is_from_task来的
		//我就执行还要传输多少次的任务
		quality_time_start = TRUE;
		if(is_think_node) {return;}
		if(!QualityTimer_is_from_task)
		//得到了还需要传多少次
		{times_left = 0;
		times_left = call LinkEstimator.Gettimes(&qualityMsgBuffer, sizeof(link_header));}
		dbg("lab", "times_left: %d\n", times_left);
		post sendQualityTask();
		dbg("lab", "Quality Timer fired at %s\n", sim_time_string());
	}
	/*event void BeaconTimer.fired(){
		post sendBeaconTask();
		dbg("lab11", "Beacon timer fired at %s\n", sim_time_string());
	}*/
	event void LinkEstimator.evicted(am_addr_t neighbor){return;}
	event void AMControl.stopDone(error_t err) {return;}
	event void Control.stopDone(error_t error) {return;}
	event void SerialSend.sendDone(message_t* msg, error_t error){return;}
	event void TDMAControl.stopDone(error_t err) {return;}
	event void EASAP.frameChanged(uint16_t newframe){return;}
	event void EASAP.frameseted(uint16_t newframe){return;}

    }











