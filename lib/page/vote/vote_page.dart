import 'package:create_event2/page/vote/add_vote_page.dart';
import 'package:create_event2/page/vote/vote_multiple.dart';
import 'package:create_event2/page/vote/vote_result.dart';
import 'package:create_event2/page/vote/vote_single.dart';
import 'package:create_event2/provider/vote_provider.dart';
import 'package:create_event2/page/vote/voteList.dart';
import 'package:create_event2/services/http.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../model/event.dart';
import '../../model/vote.dart';
import '../../services/sqlite.dart';
import '../login_page.dart';

class VotePage extends StatefulWidget {
  final Event? event;

  const VotePage({
    this.event,
    Key? key,
  }) : super(key: key);

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  // TextEditingController questionController = TextEditingController();
  late DateTime endTime;
  bool isChecked = false;

  late List<dynamic> _votes = [];
  List<Vote> voteTest = [];

  @override
  void initState() {
    super.initState();
    endTime = DateTime.now();
    getallVote();
    // startVoteCronJob();
  }

  // 抓投票資料表的資料
  getallVote() async {
    // print('widget.event.eID');
    // print(widget.event!.eID!); // 這裡要抓聊天室ID
    // String voteName = questionController.text;
    // Vote vote = Vote(
    //   vID: 1,
    //   eID: widget.event!.eID!,
    //   userMall: FirebaseEmail, // 這裡要根據使用者的userMall
    //   voteName: voteName,
    //   endTime: endTime,
    //   singleOrMultipleChoice: isChecked,
    // );

    final result =
        await APIservice.seletallVote(eID: widget.event!.eID!); // 這裡要抓聊天室ID
    print('getallVote');
    print(result[1]);
    if (result[0]) {
      setState(() {
        // 將從數據庫中獲取的Map列表轉換為Vote對象列表
        _votes = result[1].map((map) => Vote.fromMap(map)).toList();
      });
    } else {
      print('$result 在 server 抓取投票失敗');
    }
  }

  Future<void> _confirmDeleteDialog(
      BuildContext context, int index, Vote voteTest) async {
    // 11/20 更改--增加Vote voteTest

    // 返回一个对话框
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('確認刪除此投票？'),
          actions: <Widget>[
            TextButton(
              child: Text('是'),
              onPressed: () async {
                // 调用API service删除投票和相关选项
                final List result = await APIservice.deleteVote(
                    vID: voteTest.vID); // 11/20 更改--可根據vid刪除投票
                final List result1 = await APIservice.deleteVoteOptions(
                    vID: voteTest.vID); // 11/20 更改--可根據vid刪除投票選項
                print(result[0]);
                if (result[0]) {
                  print('在server刪除投票成功');
                  //_votes:是存放投票的list，當我們刪除投票時，也要同時刪除這個list中的投票，並且透過setState及時更新畫面
                  setState(() {
                    _votes.removeAt(index);
                  });
                } else {
                  print('在server刪除投票失敗');
                }
                if (result1[0]) {
                  print('在server刪除投票選項成功');
                } else {
                  print('在server刪除投票選項失敗');
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('否'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final voteProvider = Provider.of<VoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投票列表', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Color(0xFF4A7DAB),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            // 新增投票
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVotePage(
                    eID: widget.event!.eID!,
                  ),
                ),
              );
              if (result != null && result is Vote) {
                voteProvider.addVote(result);
              }
              // add_vote.dart中的Navigator.pop(context, vote);會將投票資料回傳到這裡
              //如果結果為 true，則重新加載數據
              if (result == true) {
                getallVote();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
            ),
          ),
          ListView.builder(
            itemCount: _votes.length,
            itemBuilder: (context, index) {
              final vote = _votes[index];
              return InkWell(
                onTap: () {
                  // 点击卡片导航到投票结果页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoteResultPage(
                        voteName: vote.voteName,
                        vID: vote.vID,
                        event: widget.event,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  elevation: 5.0,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vote.voteName,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '截止時間 : ${DateFormat('yyyy/MM/dd HH:mm').format(vote.endTime)}',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFF4A7DAB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                DateTime.now().isBefore(vote.endTime)
                                    ? "投票"
                                    : "查看结果",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () async {
                                // 根据投票的截止时间检查是否可以进行投票
                                if (DateTime.now().isBefore(vote.endTime)) {
                                  // 根据投票类型导航到不同的投票页面
                                  if (vote.singleOrMultipleChoice) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VoteCheckbox(
                                          vote: vote,
                                          event: widget.event,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SingleVote(
                                          vote: vote,
                                          event: widget.event,
                                        ),
                                      ),
                                    );
                                    await APIservice.addVoteResult(
                                        content: vote.tomap());
                                  }
                                } else {
                                  // 如果投票已结束，导航到投票结果页面
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VoteResultPage(
                                        voteName: vote.voteName,
                                        vID: vote.vID,
                                        event: widget.event,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _confirmDeleteDialog(context, index, vote);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void startVoteCronJob() {
    var cron = Cron();
    cron.schedule(Schedule.parse('*/1 * * * *'), () async {
      await checkVoteEndTime();
    });
  }

  Future<void> checkVoteEndTime() async {
    DateTime now = DateTime.now();
    for (var vote in _votes) {
      if (now.isAtSameMomentAs(vote.endTime) || now.isAfter(vote.endTime)) {
        final result = await APIservice.votematch(vID: vote.vID);
      }
    }
  }
}
