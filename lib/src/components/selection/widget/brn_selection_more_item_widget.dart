import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xl_flutter/bruno.dart';
import 'package:xl_flutter/src/components/picker/time_picker/brn_date_picker_constants.dart';
import 'package:xl_flutter/src/components/selection/brn_selection_util.dart';
import 'package:xl_flutter/src/components/selection/widget/brn_selection_date_range_item_widget.dart';

///更多的筛选项里面的single 项
///主要是分为两种：标签（楼层）和跳到其他页面的layer（商圈）
///标签类型包罗了：标题、有无更多的展开收起、自定义输入、标签项
///页面类型保罗了：标题、选择框
// ignore: must_be_immutable
class BrnMoreSelectionWidget extends StatefulWidget {
  //entity 是商圈、钥匙等
  final BrnSelectionEntity selectionEntity;
  final StreamController<ClearEvent> clearController;
  final BrnOnCustomFloatingLayerClick onCustomFloatingLayerClick;
  BrnSelectionConfig themeData;

  BrnMoreSelectionWidget(
      {this.selectionEntity,
      this.clearController,
      this.onCustomFloatingLayerClick,
      this.themeData});

  @override
  _BrnMoreSelectionWidgetState createState() => _BrnMoreSelectionWidgetState();
}

class _BrnMoreSelectionWidgetState extends State<BrnMoreSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    //弹出浮层
    if (widget.selectionEntity.filterType == BrnSelectionFilterType.Layer ||
        widget.selectionEntity.filterType == BrnSelectionFilterType.CustomLayer) {
      return FilterLayerTypeWidget(
        selectionEntity: widget.selectionEntity,
        onCustomFloatingLayerClick: widget.onCustomFloatingLayerClick,
        themeData: widget.themeData,
      );
    }
    //标签类型
    return _FilterCommonTypeWidget(
      selectionEntity: widget.selectionEntity,
      clearController: widget.clearController,
      themeData: widget.themeData,
    );
  }
}

/// 展示标签的布局：标题+更多+标签+自定义
// ignore: must_be_immutable
class _FilterCommonTypeWidget extends StatefulWidget {
  //楼层
  final BrnSelectionEntity selectionEntity;
  final StreamController<ClearEvent> clearController;
  BrnSelectionConfig themeData;

  _FilterCommonTypeWidget({this.selectionEntity, this.clearController, this.themeData});

  @override
  __FilterCommonTypeWidgetState createState() => __FilterCommonTypeWidgetState();
}

class __FilterCommonTypeWidgetState extends State<_FilterCommonTypeWidget> {
  bool isExpanded = false;

  ///展开收起的通知
  ValueNotifier valueNotifier;

  ///用于 range和 tag 之间通信
  StreamController<Event> streamController;

  @override
  void initState() {
    super.initState();
    streamController = StreamController.broadcast();

    //如果是输入事件
    //如果是单选的情况，将选中的tag清空
    //如果是多选则，不作处理
    streamController.stream.listen((event) {
      if (event is InputEvent) {
        setState(() {
          if (!event.filter) {
            //将所有tag设置为未选中
            event.rangeEntity.parent?.currentTagListForEntity()?.forEach((data) {
              data.clearSelectedEntity();
            });
          }
        });
      }
    });

    //展开收起的事件
    valueNotifier = ValueNotifier(isExpanded);
    valueNotifier.addListener(() {
      setState(() {
        isExpanded = valueNotifier.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 20, right: _isVisibleMore() ? 40 : 0),
                child: _buildTitleWidget(),
              ),
              //自定义输入框
              _buildRangeWidget(),
              //标签的筛选条件
              Visibility(
                visible: widget.selectionEntity.currentShowTagByExpanded(isExpanded).length > 0,
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: _buildSelectionTag(),
                ),
              )
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Visibility(
              visible: _isVisibleMore(),
              child: _MoreArrow(
                valueNotifier: valueNotifier,
                themeData: widget.themeData,
              ),
            ),
          )
        ],
      ),
    );
  }

  bool _isVisibleMore() {
    return widget.selectionEntity.currentTagListForEntity().length >
        widget.selectionEntity.getDefaultShowCount();
  }

  ///标题和更多，比如商圈
  ///更多的展示逻辑：可展示的标签>默认展示的标签
  ///比如 后端下发 默认展示3个，但是可展示的只有2个，则不展示更多
  ///可展示标签：目前的逻辑为：非自定义的项
  Widget _buildTitleWidget() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            widget.selectionEntity.title ?? "",
            style: widget.themeData.titleForMoreTextStyle.generateTextStyle(),
          ),
        ),
      ],
    );
  }

  /// 自定义筛选条件的显示
  Widget _buildRangeWidget() {
    return widget.selectionEntity.currentRangeListForEntity().isEmpty
        ? Container(
            height: 0,
            width: 0,
          )
        : _MoreRangeWidget(
            themeData: widget.themeData,
            streamController: streamController,
            clearController: widget.clearController,
            rangeEntity: widget.selectionEntity.currentRangeListForEntity()[0],
          );
  }

  /// 标签的筛选条件显示  单选和多选是由 父节点控制
  /// 如果是单选： 先将选中的清空、再添加选中
  /// 如果是多选： 直接添加筛选项
  Widget _buildSelectionTag() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      addRepaintBoundaries: false,
      childAspectRatio: 2.4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: NeverScrollableScrollPhysics(),
      children: widget.selectionEntity
          .currentShowTagByExpanded(isExpanded)
          .map((BrnSelectionEntity data) {
        return GestureDetector(
          onTap: () {
            setState(() {
              if (data.filterType == BrnSelectionFilterType.Radio) {
                data.parent.clearSelectedEntity();
                data.isSelected = true;
                //用于发送 标签点击事件
                streamController.add(SelectEvent());
              } else if (data.filterType == BrnSelectionFilterType.Checkbox) {
                if (!data.isSelected) {
                  if (!BrnSelectionUtil.checkMaxSelectionCount(data)) {
                    BrnToast.show('您选择的筛选条件数量已达上限', context);
                    return;
                  }
                }

                data.parent.children
                    ?.where((_) => _.filterType == BrnSelectionFilterType.Radio)
                    ?.forEach((f) => f.isSelected = false);
                data.isSelected = !data.isSelected;
                //用于发送 标签点击事件
                streamController.add(SelectEvent());
              } else if (data.filterType == BrnSelectionFilterType.Date) {
                _showDatePicker(data);
              }
            });
          },
          child: _buildSingleTag(data),
        );
      }).toList(),
    );
  }

  Widget _buildSingleTag(BrnSelectionEntity data) {
    bool isDate = data.filterType == BrnSelectionFilterType.Date;

    String showName;

    if (isDate) {
      if (data.value == null || data.value.isEmpty) {
        showName = data.title;
      } else {
        int time = int.tryParse(data.value ?? "") ?? DateTime.now().millisecondsSinceEpoch;
        showName = DateTimeFormatter.formatDate(
            DateTime.fromMillisecondsSinceEpoch(time), 'yyyy/MMMM/dd', DateTimePickerLocale.zh_cn);
      }
    } else {
      showName = data.title;
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: data.isSelected
              ? widget.themeData.tagSelectedBackgroundColor
              : widget.themeData.tagNormalBackgroundColor,
          borderRadius: BorderRadius.circular(widget.themeData.tagRadius)),
      height: 34,
      child: Text(
        showName,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: data.isSelected ? _selectedTextStyle() : _tagTextStyle(),
      ),
    );
  }

  TextStyle _tagTextStyle() {
    return widget.themeData.tagNormalTextStyle?.generateTextStyle();
  }

  TextStyle _selectedTextStyle() {
    return widget.themeData.tagSelectedTextStyle?.generateTextStyle();
  }

  void _showDatePicker(BrnSelectionEntity data) {
    int time = int.tryParse(data.value ?? "") ?? DateTime.now().millisecondsSinceEpoch;
    BrnDatePicker.showDatePicker(context,
        pickerMode: BrnDateTimePickerMode.date,
        pickerTitleConfig: BrnPickerTitleConfig.Default,
        initialDateTime: DateTime.fromMillisecondsSinceEpoch(time),
        dateFormat: 'yyyy年,MMMM月,dd日', onConfirm: (dateTime, list) {
      if (mounted) {
        setState(() {
          data.parent.clearSelectedEntity();
          data.isSelected = true;
          data.value = dateTime.millisecondsSinceEpoch.toString();
        });
      }
    }, onChange: (dateTime, list) {}, onCancel: () {}, onClose: () {});
  }
}

/// 更多和箭头widget
// ignore: must_be_immutable
class _MoreArrow extends StatefulWidget {
  ///用于通知 展开和收起
  final ValueNotifier valueNotifier;

  BrnSelectionConfig themeData;

  _MoreArrow({this.valueNotifier, this.themeData});

  @override
  __MoreArrowState createState() => __MoreArrowState();
}

class __MoreArrowState extends State<_MoreArrow> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    String asset = isExpanded ? BrnAsset.ICON_UP_ARROW : BrnAsset.ICON_DOWN_ARROW;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
          if (widget.valueNotifier != null) {
            widget.valueNotifier.value = isExpanded;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.only(top: 20, bottom: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '更多',
              style: widget.themeData.moreTextStyle.generateTextStyle(),
            ),
            Container(
              height: 16,
              width: 16,
              padding: EdgeInsets.only(left: 4),
              child: BrunoTools.getAssetImage(
                asset,
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// 自定义筛选条件
// ignore: must_be_immutable
class _MoreRangeWidget extends StatefulWidget {
  ///用于标签和自定义输入 通信
  final StreamController streamController;

  ///用于自定义的筛选条件 最大值最小值
  final BrnSelectionEntity rangeEntity;

  ///用于监听重置事件
  final StreamController<ClearEvent> clearController;

  BrnSelectionConfig themeData;

  _MoreRangeWidget(
      {this.streamController, this.rangeEntity, this.clearController, this.themeData, Key key})
      : super(key: key);

  @override
  __MoreRangeWidgetState createState() => __MoreRangeWidgetState();
}

class __MoreRangeWidgetState extends State<_MoreRangeWidget> {
  //最小值 输入框监听
  TextEditingController minController;

  //最大值 输入框监听
  TextEditingController maxController;

  //最小值 焦点监听
  FocusNode minFocusNode;

  //最大值 焦点监听
  FocusNode maxFocusNode;

  //默认的最大值
  int max;

  //默认的最小值
  int min;

  @override
  void initState() {
    super.initState();
    minFocusNode = FocusNode();
    maxFocusNode = FocusNode();
    minController = TextEditingController();
    maxController = TextEditingController();

    widget?.clearController?.stream?.listen((event) {
      minController.clear();
      maxController.clear();
    });

    if (widget.rangeEntity.customMap == null) {
      widget.rangeEntity.customMap = Map<String, String>();
    }

    minController.text = (widget.rangeEntity.customMap['min'] != null)
        ? widget.rangeEntity.customMap['min']?.toString()
        : null;
    maxController.text = (widget.rangeEntity.customMap['max'] != null)
        ? widget.rangeEntity.customMap['max']?.toString()
        : null;

    min = int.tryParse(widget.rangeEntity?.extMap['min']?.toString() ?? "") ?? 0;
    max = int.tryParse(widget.rangeEntity?.extMap['max']?.toString() ?? "") ?? 9999;

    ///处理的逻辑：
    ///       1：将输入框的 文本写入 customMap中
    ///       2：如果最大值和最小值满足条件 则将range选中
    minController.addListener(() {
      if (widget.rangeEntity.filterType != BrnSelectionFilterType.Range) {
        return;
      }
      String minInput = minController.text ?? "";

      if (widget.rangeEntity.customMap == null) {
        widget.rangeEntity.customMap = {};
      }

      widget.rangeEntity.customMap['min'] = minInput;

      widget.rangeEntity.isSelected = true;
    });

    maxController.addListener(() {
      if (widget.rangeEntity.filterType != BrnSelectionFilterType.Range) {
        return;
      }
      String maxInput = maxController.text ?? "";
      if (widget.rangeEntity.customMap == null) {
        widget.rangeEntity.customMap = {};
      }

      widget.rangeEntity.customMap['max'] = maxInput;

      widget.rangeEntity.isSelected = true;
    });

    ///只要获取了焦点
    ///        如果是单选 则将选中的清楚
    ///        如果是多选 则不处理
    minFocusNode.addListener(() {
      if (minFocusNode.hasFocus) {
        widget.streamController.add(InputEvent(filter: false, rangeEntity: widget.rangeEntity));
      }
    });

    maxFocusNode.addListener(() {
      if (maxFocusNode.hasFocus) {
        widget.streamController.add(InputEvent(filter: false, rangeEntity: widget.rangeEntity));
      }
    });

    ///用于监听tab的点击事件
    ///如果父亲是单选 则将输入框清空并失去焦点，并且将自定义筛选设置为 未选中,以及更新用于显示的map
    widget.streamController.stream.listen((event) {
      if (event is SelectEvent) {
        maxController.clear();
        minController.clear();
        widget.rangeEntity.customMap?.remove('min');
        widget.rangeEntity.customMap?.remove('max');
        minFocusNode.unfocus();
        maxFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rangeEntity.filterType == BrnSelectionFilterType.DateRange) {
      return BrnSelectionDateRangeItemWidget(
          item: widget.rangeEntity,
          isNeedTitle: false,
          showTextSize: 14,
          dateFormat: DATETIME_PICKER_DATE_FORMAT,
          minTextEditingController: minController,
          maxTextEditingController: maxController,
          themeData: widget.themeData,
          onTapped: () {
            //点击选择框通知标签清空
            widget.streamController.add(InputEvent(filter: false, rangeEntity: widget.rangeEntity));
          });
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: _buildRangeField('最小值', minController, minFocusNode, widget.themeData),
          ),
          Container(
//          height: 38,
            alignment: Alignment.center,
            child: Text(
              '至',
              textAlign: TextAlign.center,
              style: widget.themeData.inputTextStyle.generateTextStyle(),
            ),
          ),
          Expanded(
            child: _buildRangeField('最大值', maxController, maxFocusNode, widget.themeData),
          ),
        ],
      );
    }
  }

  Widget _buildRangeField(
    String hint,
    TextEditingController textEditingController,
    FocusNode focusNode,
    BrnSelectionConfig themeData,
  ) {
    return Container(
      child: Center(
        child: TextField(
          focusNode: focusNode,
          textAlign: TextAlign.center,
          controller: textEditingController,
          cursorColor: BrnThemeConfigurator.instance.getConfig().commonConfig.brandPrimary,
          inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
          style: widget.themeData.inputTextStyle.generateTextStyle(),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: widget.themeData.hintTextStyle.generateTextStyle(),
              enabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.themeData.tagRadius),
                  borderSide:
                      BorderSide(width: 1, color: widget.themeData.commonConfig.borderColorBase)),
              focusedBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.themeData.tagRadius),
                  borderSide:
                      BorderSide(width: 1, color: widget.themeData.commonConfig.borderColorBase))),
        ),
      ),
    );
  }
}

/// 浮层类型的项 ： 标题 + 点击跳转的layout
// ignore: must_be_immutable
class FilterLayerTypeWidget extends StatefulWidget {
  //entity是 商圈
  final BrnSelectionEntity selectionEntity;
  final BrnOnCustomFloatingLayerClick onCustomFloatingLayerClick;
  BrnSelectionConfig themeData;

  FilterLayerTypeWidget({this.selectionEntity, this.onCustomFloatingLayerClick, this.themeData});

  @override
  _FilterLayerTypeWidgetState createState() => _FilterLayerTypeWidgetState();
}

class _FilterLayerTypeWidgetState extends State<FilterLayerTypeWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20),
          child: Text(
            widget.selectionEntity.title,
            style: widget.themeData.titleForMoreTextStyle.generateTextStyle(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 6),
          child: GestureDetector(
            onTap: () {
              if (widget.selectionEntity.filterType == BrnSelectionFilterType.Layer) {
                Navigator.of(context)
                    .push(PageRouteBuilder<BrnSelectionEntity>(
                        opaque: false,
                        pageBuilder: (context, animation, second) {
                          return BrnLayerMoreSelectionPage(
                            entityData: widget.selectionEntity,
                            themeData: widget.themeData,
                          );
                        }))
                    .then((data) {
                  updateContent();
                });
              } else if (widget.selectionEntity.filterType == BrnSelectionFilterType.CustomLayer) {
                if (widget.onCustomFloatingLayerClick != null) {
                  int entityIndex = -1;
                  if (widget.selectionEntity.parent != null &&
                      widget.selectionEntity.parent.children != null) {
                    entityIndex =
                        widget.selectionEntity.parent.children.indexOf(widget.selectionEntity);
                  }
                  widget.onCustomFloatingLayerClick(entityIndex, widget.selectionEntity,
                      (List<BrnSelectionEntity> customFloatingLayerParams) {
                    widget.selectionEntity.children?.clear();
                    widget.selectionEntity.children = [];
                    widget.selectionEntity.children.addAll(customFloatingLayerParams);
                    widget.selectionEntity.configDefaultValue();
                    setState(() {});
                  });
                }
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(isEmptyCondition() ? '请选择' : getCondition(),
                      style: isEmptyCondition()
                          ? widget.themeData.hintTextStyle.generateTextStyle()
                          : widget.themeData.optionTextStyle.generateTextStyle()),
                ),
                Container(
                  height: 16,
                  width: 16,
                  child: BrunoTools.getAssetImage(BrnAsset.ICON_RIGHT_ARROW),
                )
              ],
            ),
          ),
        ),
        Padding(padding: EdgeInsets.only(top: 15), child: BrnLine())
      ],
    );
  }

  void updateContent() {
    setState(() {});
  }

  bool isEmptyCondition() {
    String condition = getCondition();
    return condition == null || condition.isEmpty;
  }

  String getCondition() {
    String tmp = "";
    //返回所有选中的
    List<BrnSelectionEntity> selectedList = widget.selectionEntity.selectedList();

    //判断步骤：
    //第一步：取出来所有选中的： 房山 不限 小白楼 西城 不限
    //第二步：判断显示的条件（非不限，没有选中的子节点）
    //       比如：房山 的不限---需要展示房山，但是由于选了房山的小白楼 则显示小白楼
    //场景1 ： 选中了房山的不限
    //       selectedList返回了 房山   不限
    //       迭代房山是非不限  并且没有选中的非不限子节点    结果会添加房山
    //       迭代了不限      不限是不限类型    结果不添加不限
    //场景2 ： 选中了房山的小白楼
    //        selectedList返回了 房山   小白楼
    //        迭代房山是非不限  并且有选中的非不限子节点    结果不会添加房山
    //        迭代小白楼是非不限  并且没有有选中的非不限子节点    结果添加小白楼

    //过滤规则
    //  1：滤掉不限
    //  2：滤掉有选中的非不限的叶子节点
    List<BrnSelectionEntity> result = selectedList.where((value) {
      return !value.isUnLimit() && value.selectedListWithoutUnlimit().isEmpty;
    }).toList();

    for (int i = 0; i < result.length; i++) {
      tmp += result[i].title;
      if (i != result.length - 1) {
        tmp += '、';
      }
    }
    return tmp;
  }
}

/// tag 和 range 之间的通信
abstract class Event {}

/// tag点击的事件
class SelectEvent extends Event {}

/// 输入框的事件:携带 自定义的筛选条件 和 过滤标识位
/// 由于点击标签之后，会清空筛选条件，清空的时候，textField的监听也会执行一遍，因此需要过滤
class InputEvent extends Event {
  BrnSelectionEntity rangeEntity;
  bool filter;

  InputEvent({this.rangeEntity, this.filter});
}