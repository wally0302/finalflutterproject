import 'package:create_event2/page/vote/vote_page.dart';
import 'package:flutter/material.dart';
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
                      // 確保 _voteOptions[index].votingOptionContent 不為空
                      if (_voteOptions[index].votingOptionContent.isNotEmpty) {
                        // 提取並分割日期範圍
                        String dateRangeString =
                            _voteOptions[index].votingOptionContent[0];
                        List<String> dateRange = dateRangeString.split('~ ');

                        String formattedDateRange = '';
                        if (dateRange.length == 2) {
                          // 格式化日期
                          String formattedStart = formatDateTime(dateRange[0]);
                          String formattedEnd = formatDateTime(dateRange[1]);
                          formattedDateRange =
                              "$formattedStart ~ $formattedEnd";
                        } else {
                          formattedDateRange = "Invalid Date Range";
                        }

                        // 組合格式化的日期範圍和票數
                        String optionText = "$formattedDateRange：" +
                            _oIDtoCount[index].toString();

                        print(optionText);

                        return ListTile(
                          title: Text(
                            optionText,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      } else {
                        return ListTile(
                          title: Text(
                            "No Date Provided",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      );
    });
  }

  String formatDateTime(String dateTime) {
    String year = dateTime.substring(0, 4);
    String month = dateTime.substring(4, 6);
    String day = dateTime.substring(6, 8);
    String time = dateTime.substring(8, 12);

    return "$year/$month/$day/$time";
  }
}
