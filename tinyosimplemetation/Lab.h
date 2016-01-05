#ifndef LAB_H
#define LAB_H
#include "EASAP.h"
#include "TDMA.h"
enum {

   UART_QUEUE_LEN = 50,
   RADIO_QUEUE_LEN = 50,
   UART_RADIO_LEN = 350,
   SET_TRANS_DELAY = DEFAULT_INTERVAL/10, // 10%. Set THIS parameter for transmission delay
   MIN_TRANS_DELAY = 64, //Hard tested. Needs to be Above 40 for safety.
   TEST_FRAME_NUMBER = 20,
   TRANS_DELAY = (SET_TRANS_DELAY < MIN_TRANS_DELAY) ? MIN_TRANS_DELAY:SET_TRANS_DELAY,
};

//此消息用来测试看看schedule的信息，用来发往sinknode
typedef struct test_type_msg {
  am_addr_t my_address;//我的地址
  uint32_t seq;//我这条message的sequence number
} test_type_msg_t;

typedef nx_struct radio_type_msg {//此信息是放在beacon中实现的，通过beacon来交换信息
  nx_uint8_t messagetype;//等于1代表是广播我等级是多少的消息
  nx_uint8_t node_level;//放在包头用来表示该节点的等级
} radio_type_msg_t;


typedef struct {
  am_addr_t parent;
  uint8_t parent_level;

} route_info_t;
//用链表结构存储我想要抵达节点，需要经过哪个节点在周转实现
struct relayinginfo{
	am_addr_t relay;//用来记录是哪个子节点来的信息，需要通过这个子节点relay传播， 即收到的MSG的地址值
	am_addr_t destination;//用来记录想要去哪里，是目标最终的节点，从thinknode往下传的节点，匹配的时候需要用这个节点匹配
	struct relayinginfo *prev;//上一个记录
	struct relayinginfo *next;//赚到下一个记录
};

typedef struct {
  message_t message;
  uint8_t payloadlength;
} message_forward_t;


//下面这个结构体用来传输，放到消息的头里面
//用来传输link quality 的
typedef struct {
//messagetype等于2说明是用来传播链路质量用的
//**************************************************
//这个里面应该还要加一个 flags 的后四位用来作为可以容纳15个Numberof entries of footer
  am_addr_t myaddress;
  uint8_t messagetype;
  uint8_t flags;

} link_header_t;

#endif
