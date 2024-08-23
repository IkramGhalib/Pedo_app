import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meter_reading/Database/controller.dart';
import 'package:meter_reading/models/contactinfomodel.dart';
import 'package:meter_reading/screens/readings/widgets/view_my_photo.dart';
import 'package:path_provider/path_provider.dart';

class Readings extends StatefulWidget {
  final String monthYear;
  const Readings(this.monthYear, {super.key});

  @override
  State<Readings> createState() => _ReadingsState();
}

const Map<String, String> monthMappings = {
  '01': 'Jan',
  '02': 'Feb',
  '03': 'Mar',
  '04': 'Apr',
  '05': 'May',
  '06': 'Jun',
  '07': 'Jul',
  '08': 'Aug',
  '09': 'Sep',
  '10': 'Oct',
  '11': 'Nov',
  '12': 'Dec',
};

class _ReadingsState extends State<Readings> {
  List<ContactinfoModel> meterRecords = [];
  int unitDifference = 0;

  bool isExpended = false;
  List<bool> isListOpen = [];
  List<bool> listAllFalse = [];

  void updateTable(int refNo, int curReading) async {
    int result = await Controller().updateOnlyRequiredField(refNo, curReading);
    if (result > 0) {
      updateContactList(refNo, curReading);
    } else {
      EasyLoading.showError('Update failed please try again!');
    }

    setState(() {});
    return;
  }

  final TextEditingController _updateFieldController = TextEditingController();

  Future meterList() async {
    meterRecords = await Controller().fetchData();
    setState(() {});
  }

  void updateContactList(int refNoArg, int curReadingArg) {
    for (var meter in meterRecords) {
      if (meter.refNo == refNoArg) {
        meter.curReading = curReadingArg;
        return;
      }
    }
    return;
  }

  void deleteSingleImageTemp(String path) {
    Controller().deleteSingleImage(path);
  }

  void deleteAllImagesInFolder() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String folderPath = directory.path;

    Directory(folderPath).listSync().forEach((file) {
      if (file is File && file.path.endsWith('.png') ||
          file.path.endsWith('.jpg') ||
          file.path.endsWith('.jpeg')) {
        file.deleteSync();
      }
    });
  }

  void _deleteAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All'),
          content: const Text('Are you sure to proceed?'),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No')),
            TextButton(
              onPressed: () async {
                deleteAllImagesInFolder();
                await Controller().deleteData().then((value) {
                  if (value > 0) {
                    setState(() {
                      meterRecords.clear();
                    });
                  } else {}
                });

                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  String? validateUpdateInput(String value) {
    if (_updateFieldController.text.isEmpty) {
      return 'should not empty';
    }
    if (value.isEmpty) {
      return 'Please enter a valid number';
    }
    return null;
  }

  void _showDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Invalid Input'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  void _presentUpdateSheet(
      BuildContext context, int refNo, int oldCurReading, int preReading) {
    _updateFieldController.text = '$oldCurReading';
    showModalBottomSheet(
      useSafeArea: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 12,
              ),
              const Text('Update Readings'),
              const SizedBox(height: 25),
              TextField(
                maxLength: 8,
                controller: _updateFieldController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Update Reading'),
                    hintText: 'Enter new reading'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_updateFieldController.text.isEmpty) {
                      _showDialog('Current reading cannot be empty');
                      return;
                    }
                    if (int.parse(_updateFieldController.text) < preReading) {
                      _showDialog(
                          'Current reading cannot be less than previous reading');
                      return;
                    }

                    if (_updateFieldController.text.isNotEmpty) {
                      updateTable(
                          refNo, int.parse(_updateFieldController.text));
                      _updateFieldController.clear();
                      Navigator.pop(context);
                    }
                    return;
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    meterList();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _updateFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String monthYear = widget.monthYear;
    String monthNumber = monthYear.substring(5);
    String monthText = monthMappings[monthNumber] ?? 'Not-set';
    String formattedDate = monthYear.replaceRange(5, null, monthText);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readings'),
        actions: [
          Center(
              child: Text(
            '$formattedDate  ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          )),
          const VerticalDivider(
            endIndent: 15,
            indent: 15,
            color: Colors.white,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: ListTile(
                  onTap: _deleteAll,
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Color(0xFF243A92),
                  ),
                  title: const Text(
                    '  Delete All',
                    style: TextStyle(
                      color: Color(0xFF243A92),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: meterRecords.isEmpty
          ? const Center(
              child: Text('No meter record found'),
            )
          : Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(
                          2), // 40% of available width for the 1st column
                      1: FlexColumnWidth(1), // 20% for the 2nd column
                      2: FlexColumnWidth(1), // 20% for the 3rd column
                      3: FlexColumnWidth(1), // 20% for the 4th column
                    },
                    children: const [
                      TableRow(
                        children: [
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Text(
                                'Ref No',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              )),
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Text(
                                'Meter No',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              )),
                          TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Text(
                              'Units',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Icon(Icons.article),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: meterRecords.length,
                      itemBuilder: (context, index) {
                        isListOpen.add(false);
                        listAllFalse.add(false);
                        unitDifference = meterRecords[index].curReading -
                            meterRecords[index].preReading;

                        return Card(
                          color: const Color.fromARGB(255, 216, 217, 247),
                          child: Column(
                            children: [
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(
                                      2), // 40% of available width for the 1st column
                                  1: FlexColumnWidth(
                                      1), // 20% for the 2nd column
                                  2: FlexColumnWidth(
                                      1), // 20% for the 3rd column
                                  3: FlexColumnWidth(
                                      1), // 20% for the 4th column
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Text(
                                            '${meterRecords[index].refNo}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )),
                                      TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Text(
                                            '${meterRecords[index].meterNo}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )),
                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Text(
                                          '$unitDifference',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: IconButton(
                                          onPressed: () {
                                            setState(
                                              () {
                                                if (index == 0) {
                                                  isListOpen.fillRange(1,
                                                      isListOpen.length, false);
                                                } else if (index ==
                                                    isListOpen.length) {
                                                  isListOpen.fillRange(
                                                      0, isListOpen.length - 1);
                                                } else {
                                                  isListOpen.fillRange(
                                                      0, index, false);
                                                  isListOpen.fillRange(
                                                      index + 1,
                                                      isListOpen.length,
                                                      false);
                                                }

                                                isListOpen[index] =
                                                    !isListOpen[index];
                                              },
                                            );
                                          },
                                          icon: Icon(isListOpen[index]
                                              ? Icons.keyboard_arrow_down
                                              : Icons.keyboard_arrow_up),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isListOpen[index] == true)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    DataTable(
                                      columns: [
                                        const DataColumn(
                                          label: Text(
                                            'Cur Reading',
                                            style: TextStyle(
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                        DataColumn(
                                          label: GestureDetector(
                                            onTap: () {
                                              _presentUpdateSheet(
                                                  context,
                                                  meterRecords[index].refNo,
                                                  meterRecords[index]
                                                      .curReading,
                                                  meterRecords[index]
                                                      .preReading);
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${meterRecords[index].curReading} ',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
                                                const Icon(
                                                  Icons.edit,
                                                  size: 15,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: [
                                        dataRow('Pre Reading',
                                            '${meterRecords[index].preReading}'),
                                        dataRow('Meter Status',
                                            meterRecords[index].status),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ViewMyPhoto(
                                              path: meterRecords[index]
                                                  .offPeakImage!,
                                              refNo: meterRecords[index].refNo,
                                              fetchMeters: meterList,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: meterRecords[index]
                                                    .offPeakImage !=
                                                ''
                                            ? Image.file(
                                                File(
                                                  meterRecords[index]
                                                      .offPeakImage!,
                                                ),
                                                width: 70,
                                                height: 70,
                                                cacheHeight: 70,
                                                cacheWidth: 70,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                alignment: Alignment.center,
                                                color: const Color.fromARGB(
                                                    255, 227, 234, 249),
                                                width: 70,
                                                height: 70,
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  DataRow dataRow(
    String fieldName,
    String fieldValue,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(fieldName)),
        DataCell(Text(fieldValue)),
      ],
    );
  }

  TableRow tableRow(String fieldName, String fieldValue, Icon icon) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(
            fieldName,
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(
            fieldValue,
          ),
        ),
      ],
    );
  }
}
