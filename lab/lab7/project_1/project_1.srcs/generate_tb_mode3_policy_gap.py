# 本文件的作用主要为了生成测试文件mem_bram.v和cache_tb.v
# 生成的mem_bram.v文件主要是初始化内存中的数据，用于后续的随机读写操作
# 生成的cache_tb.v文件主要是模拟CPU对cache的读写操作，用于验证cache的正确性

# 定义一些仿真文件参数
MODE = 3 # 0:随机读写 1：模拟CPU伪顺序读写（会有不定期跳转，概率为BranchP） 3：强相关且可区分替换策略的访问
BranchP = 0.1 # 跳转概率，仅在MODE=1时有效，当BranchP = 0时，为顺序读写不会跳转
PHASE_MIN_LEN = 180 # MODE=3：一个局部工作阶段的最短访问次数
PHASE_MAX_LEN = 360 # MODE=3：一个局部工作阶段的最长访问次数
ACTIVE_SET_NUM = 4 # MODE=3：每个阶段主要活跃的cache set数量
HOT_LINES_PER_SET = 12 # MODE=3：每个活跃set中反复访问的热cache line数量
COLD_LINES_PER_SET = 14 # MODE=3：每个活跃set中用于制造替换压力的冷cache line数量
HOT_TOUCH_ROUNDS = 2 # MODE=3：每次干扰前重复触碰热line的轮数
COLD_BURST_LEN = 6 # MODE=3：一次冷数据扫描连续访问的line数量
CONFLICT_BURST_P = 0.32 # MODE=3：进入同set冷数据干扰的概率
NEARBY_SEQ_P = 0.18 # MODE=3：访问普通相邻数据的概率
RANDOM_ACCESS_P = 0.04 # MODE=3：访问全局随机地址的概率
READ_NUM   = 2000 # 读取次数
WRITE_NUM  = 1000 # 写入次数

# 内存参数
WORD_WIDTH = 32 # 内存数据宽度
DATA_WIDTH = 128 # 一行数据宽度

# cache参数
INDEX_WIDTH = 3
LINE_OFFSET_WIDTH = 2
SPACE_OFFSET = 2
MEM_ADDR_WIDTH = 10
WAY_NUM = 2
WAY_WIDTH = 1
# 生成mem_bram.v文件
from random import randint

mem_bram_head = '''
`timescale 1ns/1ps
module mem_bram #(
    parameter ADDR_WIDTH = 10,		//地址宽度
    parameter DATA_WIDTH = 128		//数据宽度
)(
    input                   clk,   // Clock
    input [ADDR_WIDTH-1:0]  raddr,  // Address
    input [ADDR_WIDTH-1:0]  waddr,  // Address
    input [DATA_WIDTH-1:0]  din,   // Data Input
    input                   we,    // Write Enable
    output [DATA_WIDTH-1:0] dout   // Data Output
); 
    reg [ADDR_WIDTH-1:0] addr_r;  // Address Register
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];
    integer i;
    initial begin
'''

mem_bram_tail = '''
    end
    always @(posedge clk) begin
        addr_r <= raddr;
        if(we) ram[waddr] <= din;
    end
    assign dout = ram[addr_r]; 

endmodule
'''

mem= {} # 内存数据，地址为4对齐(即低2位为0), 数据为32位
for i in range(1 << MEM_ADDR_WIDTH):
    mem[i] = randint(0, 2**WORD_WIDTH-1)

with open('./src/mem_bram.v', 'w', encoding="utf-8") as f:
    f.write(mem_bram_head)
    # 根据LINE_OFFSET_WIDTH，将多个内存数据合并成一行
    for i in range(0, 1 << MEM_ADDR_WIDTH, 1 << LINE_OFFSET_WIDTH):
        for j in range(1 << LINE_OFFSET_WIDTH):
            f.write('        ram[%d][%d:%d] = 32\'d%d;\n' % ((i+j)>>SPACE_OFFSET, (j+1)*WORD_WIDTH-1, j*WORD_WIDTH, mem[i+j]))
    f.write(mem_bram_tail)

# 生成cache_tb.v文件
cache_tb_head = '''
/*
本文件是一个测试文件，用于测试cache模块
工作原理是模仿CPU的读写请求，对cache进行读写操作
将Cache返回的数据与预先数据进行比较，如果一致则测试通过
*/
`timescale 1ns/1ps
module cache_tb();

'''

cache_tb_body = '''
    // 变化的信号 CPU发出
    reg clk=1;
    reg rstn=1;
    reg stat=0;
    // 等rstn信号稳定后 clk信号才开始翻转
    initial begin
        #1 rstn = 0;
        #1 rstn = 1;
        stat = 1;
    end
    always  #1 clk = ~clk;

    wire [31:0] addr;
    wire r_req;
    wire w_req;
    wire [31:0] w_data;

    // 导线
    wire [31:0] r_data;
    wire miss;
    wire mem_r;
    wire mem_w;
    wire [31:0] mem_addr;
    wire [127:0] mem_w_data;
    wire [127:0] mem_r_data;
    wire mem_ready;

    // 用于测试的信号
    reg [MEM_ADDR_WIDTH-1:0] test_addr[0:READ_NUM+WRITE_NUM-1];  // 用于存储测试地址
    reg [32:0] test_data[0:READ_NUM+WRITE_NUM-1];  // 用于存储测试数据 最高位用于标记是否写入 0：读 1：写
    reg [31:0] test_cnt=0;  // 用于计数，每次读写操作后加1
    reg diff=0;  // 用于标记是否有不一致的数据

    // 用于对比的提交，当前cache应该给出的数据
    wire op;
    wire[31:0] data;
    assign op = test_data[test_cnt-1][32];
    assign data = test_data[test_cnt-1][31:0];
    
    // 状态机
    assign addr = test_addr[test_cnt]<<SPACE_OFFSET;
    assign r_req = test_data[test_cnt][32] == 0 ? 1 : 0;
    assign w_req = test_data[test_cnt][32] == 1 ? 1 : 0;
    assign w_data = test_data[test_cnt][31:0];
    always @(posedge clk) begin
        if (!miss && (test_cnt < READ_NUM+WRITE_NUM) && stat) begin
            if (test_data[test_cnt-1][32] == 0) begin  // 读
                if (r_data != test_data[test_cnt-1][31:0]) begin
                    $display("Read error at %d, expect %h, get %h", test_cnt, test_data[test_cnt-1][31:0], r_data);
                    diff = 1;
                end
            end
            test_cnt <= test_cnt + 1;
        end
    end

    // 例化cache
    cache #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .LINE_OFFSET_WIDTH(LINE_OFFSET_WIDTH),
        .SPACE_OFFSET(SPACE_OFFSET),
        .WAY_NUM(WAY_NUM),
        .WAY_WIDTH(WAY_WIDTH)
    ) cache_inst(
        .clk(clk),
        .rstn(rstn),
        .addr(addr),
        .r_req(r_req),
        .w_req(w_req),
        .w_data(w_data),
        .r_data(r_data),
        .miss(miss),
        .mem_r(mem_r),
        .mem_w(mem_w),
        .mem_addr(mem_addr),
        .mem_w_data(mem_w_data),
        .mem_r_data(mem_r_data),
        .mem_ready(mem_ready)
    );

    // 内存
    mem #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .LINE_OFFSET_WIDTH(LINE_OFFSET_WIDTH),
        .SPACE_OFFSET(SPACE_OFFSET),
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH-LINE_OFFSET_WIDTH),
        .WAY_NUM(WAY_NUM)
    ) mem_inst(
        .clk(clk),
        .rstn(rstn),
        .mem_r(mem_r),
        .mem_w(mem_w),
        .mem_addr(mem_addr),
        .mem_w_data(mem_w_data),
        .mem_r_data(mem_r_data),
        .mem_ready(mem_ready)
    );

    // 初始化测试数据
    initial begin
'''

cache_tb_tail = '''
    end
endmodule
'''

test_data = []
for i in range(READ_NUM):
    test_data.append(0)
for i in range(WRITE_NUM):
    test_data.append(randint(0, 2**WORD_WIDTH-1) | (1 << 32))

# 生成随机读写操作
if MODE == 0:
    test_addr = [randint(0, 2**MEM_ADDR_WIDTH-1) for i in range(READ_NUM+WRITE_NUM)]
elif MODE == 1:
    test_addr = [0]
    return_flag = 0
    ret_test_addr = 0
    for i in range(1, READ_NUM+WRITE_NUM):
        if randint(0, 100) < BranchP*100:
            if return_flag == 0:
                ret_test_addr = test_addr[i-1]
                return_flag = 1
                test_addr.append(randint(0, 2**MEM_ADDR_WIDTH-1))
            elif return_flag == 1:
                test_addr.append(ret_test_addr + 1)
                return_flag = 0
        else:
            test_addr.append(test_addr[i-1] + 1)
        # 确保地址不超过内存范围
        test_addr[i] = test_addr[i] % (2**MEM_ADDR_WIDTH)
elif MODE == 3:
    mem_size = 2**MEM_ADDR_WIDTH
    set_num = 1 << INDEX_WIDTH
    line_words = 1 << LINE_OFFSET_WIDTH
    total_lines = mem_size // line_words
    tag_num = total_lines // set_num

    active_set_num = min(ACTIVE_SET_NUM, set_num)
    hot_lines_per_set = min(HOT_LINES_PER_SET, tag_num-1)
    cold_lines_per_set = min(COLD_LINES_PER_SET, tag_num-hot_lines_per_set)

    def make_addr(set_idx, tag_idx, word_offset=0):
        line_idx = tag_idx * set_num + set_idx
        return (line_idx * line_words + word_offset) % mem_size

    test_addr = []
    pending_addr = []
    phase_left = 0
    active_sets = []
    hot_tags = {}
    cold_tags = {}
    hot_cursor = {}
    cold_cursor = {}
    nearby_base = 0
    nearby_pos = 0

    for i in range(READ_NUM+WRITE_NUM):
        if phase_left <= 0:
            # 一个phase模拟程序在一段时间内集中处理几个数组/结构体所在的set。
            phase_left = randint(PHASE_MIN_LEN, PHASE_MAX_LEN)
            active_sets = []
            while len(active_sets) < active_set_num:
                set_idx = randint(0, set_num-1)
                if set_idx not in active_sets:
                    active_sets.append(set_idx)

            hot_tags = {}
            cold_tags = {}
            hot_cursor = {}
            cold_cursor = {}
            for set_idx in active_sets:
                base_tag = randint(0, tag_num-1)
                hot_tags[set_idx] = [(base_tag + j) % tag_num for j in range(hot_lines_per_set)]
                cold_tags[set_idx] = [(base_tag + hot_lines_per_set + j) % tag_num for j in range(cold_lines_per_set)]
                hot_cursor[set_idx] = randint(0, hot_lines_per_set-1)
                cold_cursor[set_idx] = randint(0, cold_lines_per_set-1)

            nearby_base = randint(0, mem_size-1)
            nearby_pos = 0

        if len(pending_addr) == 0:
            sel = randint(0, 9999) / 10000.0
            set_idx = active_sets[randint(0, len(active_sets)-1)]

            if sel < CONFLICT_BURST_P:
                # 真实程序中常见的模式：热数据反复使用，随后扫入一小段同set冷数据。
                # LRU/PLRU会更倾向保留刚被触碰过的热line；FIFO和随机更容易误伤热line。
                for r in range(HOT_TOUCH_ROUNDS):
                    for h in range(hot_lines_per_set):
                        hot_cursor[set_idx] = (hot_cursor[set_idx] + 1) % hot_lines_per_set
                        pending_addr.append(make_addr(set_idx, hot_tags[set_idx][hot_cursor[set_idx]], h % line_words))

                for c in range(COLD_BURST_LEN):
                    cold_cursor[set_idx] = (cold_cursor[set_idx] + 1) % cold_lines_per_set
                    pending_addr.append(make_addr(set_idx, cold_tags[set_idx][cold_cursor[set_idx]], c % line_words))
                    if c % 2 == 1:
                        hot_cursor[set_idx] = (hot_cursor[set_idx] + 3) % hot_lines_per_set
                        pending_addr.append(make_addr(set_idx, hot_tags[set_idx][hot_cursor[set_idx]], c % line_words))

                for h in range(hot_lines_per_set // 2):
                    hot_cursor[set_idx] = (hot_cursor[set_idx] + 1) % hot_lines_per_set
                    pending_addr.append(make_addr(set_idx, hot_tags[set_idx][hot_cursor[set_idx]], h % line_words))
            elif sel < CONFLICT_BURST_P + NEARBY_SEQ_P:
                # 普通顺序访问，不只访问冲突集合，保留真实程序的空间局部性。
                for s in range(8):
                    pending_addr.append((nearby_base + nearby_pos + s) % mem_size)
                nearby_pos = (nearby_pos + 8) % mem_size
            elif sel < CONFLICT_BURST_P + NEARBY_SEQ_P + RANDOM_ACCESS_P:
                # 少量全局随机访问，模拟不常用数据、调用栈切换或外设缓冲。
                pending_addr.append(randint(0, mem_size-1))
            else:
                # 默认访问热工作集，形成强相关性和较高复用。
                for h in range(4):
                    hot_cursor[set_idx] = (hot_cursor[set_idx] + 1) % hot_lines_per_set
                    pending_addr.append(make_addr(set_idx, hot_tags[set_idx][hot_cursor[set_idx]], h % line_words))

        test_addr.append(pending_addr.pop(0))
        phase_left -= 1

# debug
# print(test_addr)
# print(len(test_addr))
# print(test_data)
# print(len(test_data))

# 打乱test_data顺序
from random import shuffle
shuffle(test_data)
with open('./src/cache_tb.v', 'w', encoding="utf-8") as f:
    f.write(cache_tb_head)
    f.write("    //测试参数\n")
    f.write("    parameter READ_NUM = %d;  // 测试次数 这里设置为2000次读，1000次写\n" % READ_NUM)
    f.write("    parameter WRITE_NUM = %d;  \n" % WRITE_NUM)
    f.write("    //模块参数\n")
    f.write("    parameter INDEX_WIDTH       = %d;   // Cache索引位宽 2^3=8行\n" % INDEX_WIDTH)
    f.write("    parameter LINE_OFFSET_WIDTH = %d;   // 行偏移位宽，决定了一行的宽度 2^2=4字\n" % LINE_OFFSET_WIDTH)
    f.write("    parameter SPACE_OFFSET      = %d;   // 一个地址空间占1个字节，因此一个字需要4个地址空间，由于假设为整字读取，处理地址的时候可以默认后两位为0\n" % SPACE_OFFSET)
    f.write("    parameter MEM_ADDR_WIDTH    = %d;   // 为了简化，这里假设内存地址宽度为10位（CPU请求地址仍然是32位，只不过我们这里简化处理，截断了高位） \n" % MEM_ADDR_WIDTH)
    f.write("    parameter WAY_NUM           = %d;   // Cache N路组相联(N=1的时候是直接映射)\n" % WAY_NUM)
    f.write("    parameter WAY_WIDTH           = %d;    " % WAY_WIDTH)
    f.write(cache_tb_body)
    for i in range(READ_NUM+WRITE_NUM):
        f.write('        test_addr[%d] = %d;\n' % (i, test_addr[i]))
        # 模拟写入数据修改mem中的数据
        if test_data[i] >> 32 == 1:
            mem[test_addr[i]] = test_data[i] & 0xffffffff
            f.write('        test_data[%d] = 33\'d%d;\n' % (i, test_data[i]))
        else:
            f.write('        test_data[%d] = 33\'d%d;\n' % (i, mem[test_addr[i]]))
    f.write(cache_tb_tail)
