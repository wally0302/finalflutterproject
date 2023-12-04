import 'package:create_event2/page/vote/vote_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/event.dart';
import '../../model/vote.dart';
import '../../provider/vote_provider.dart';
import '../../services/http.dart';

class VoteResultPage extends StatefulWidget {
  final String voteName; //
  final int vID;
  final Event? event;

  VoteResultPage({
    required this.voteName, // 投票問題的描述，必需的參數
    required this.vID,
    this.event,
  });

  @override
  State<VoteResultPage> createState() => _VoteResultPageState();
}

class _VoteResultPageState extends State<VoteResultPage> {
  late List<dynamic> _voteOptions = []; // 存儲投票選項的資料
  List<int> _oIDtoCount = []; // 存儲每個選項的投票數

  @override
  void initState() {
    super.initState();
    getOption();
  }

  // 抓回選項內容
  getOption() async {
    print("-------------vote_result.dartgetOptionResult-----------------");

    // 獲取投票選項資料
    final result = await APIservice.seletallVoteOptions(vID: widget.vID);
    final tmpResult = result[1].map((map) => VoteOption.fromMap(map)).toList();
    List<int> tmpCount = [];
    print(tmpResult);

    // 獲取每個選項的投票數
    for (int i = 0; i < tmpResult.length; i++) {
      final resultCount = await APIservice.countVote(oID: tmpResult[i].oID);
      tmpCount.add(resultCount[1].length);
    }
    if (result[0]) {
      // 更新 state，將資料存儲在 _voteOptions 和 _oIDtoCount 中
      setState(() {
        _voteOptions = result[1].map((map) => VoteOption.fromMap(map)).toList();
        _oIDtoCount = tmpCount;
      });
      print(_oIDtoCount);
    } else {
      print('$result 在 server 抓取投票選項失敗');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoteProvider>(builder: (context, voteProvider, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('投票結果', style: TextStyle(color: Colors.black)),
          centerTitle: true, //標題置中
          backgroundColor: Color(0xFF4A7DAB), // 這裡設置 AppBar 的顏色
          iconTheme: IconThemeData(color: Colors.black), // 將返回箭头设为黑色
          automaticallyImplyLeading: false, // 不顯示返回按鈕

          actions: [
            IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/back.png',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '${widget.voteName}',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _voteOptions.length,
                    itemBuilder: (context, index) {
                      String optionContent =
                          _voteOptions[index].votingOptionContent.join(", ");
                      bool isDateRange =
                          RegExp(r'\d{12} ~ \d{12}').hasMatch(optionContent);
                      IconData iconData =
                          isDateRange ? Icons.date_range : Icons.help_outline;

                      String optionText;
                      // 格式化日期範圍或直接使用原始文本
                      if (isDateRange) {
                        DateTime startDate =
                            parseDate(optionContent.split(' ~ ')[0]);
                        DateTime endDate =
                            parseDate(optionContent.split(' ~ ')[1]);
                        String formattedStartDate =
                            DateFormat('yyyy-MM-dd HH:mm').format(startDate);
                        String formattedEndDate =
                            DateFormat('yyyy-MM-dd HH:mm').format(endDate);
                        optionText = '$formattedStartDate ~ $formattedEndDate';
                      } else {
                        optionText = optionContent;
                      }

                      return Card(
                        child: ListTile(
                          leading: Icon(iconData, color: Colors.blue),
                          title: Text(
                            optionText + "：" + _oIDtoCount[index].toString(),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  DateTime parseDate(String dateStr) {
    // 假設 dateStr 是 "202312040800~202312040900" 這樣的格式
    var StartTimeInt = int.parse(dateStr);

    return DateTime(
        StartTimeInt ~/ 100000000, // 年
        (StartTimeInt % 100000000) ~/ 1000000, // 月
        (StartTimeInt % 1000000) ~/ 10000, // 日
        (StartTimeInt % 10000) ~/ 100, // 小时
        StartTimeInt % 100 // 分钟
        );
  }
}
