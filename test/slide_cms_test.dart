import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/admin_dashboard.dart';
import 'package:brilliant_mobile/data/models/authored_lesson.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/models/mobile_catalog.dart';
import 'package:brilliant_mobile/data/models/slide_lesson.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/data/repositories/admin_repository.dart';
import 'package:brilliant_mobile/experiments/slide_lesson_workspace.dart';
import 'package:brilliant_mobile/features/admin/admin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_content_test.dart' show CmsAdminRepository;
import 'admin_dashboard_test.dart' show TestAdminAuth;

class StudioTestRepository extends CmsAdminRepository implements AdminSlideGenerator {
  final drafts=<String,Map<String,dynamic>>{};
  Map<String,dynamic>? generatedDesign;
  @override
  Future<List<Map<String,dynamic>>> generateSlides(String owner,String prompt,String topic,Map<String,dynamic> design) async {
    generatedDesign=learningCopy(design);
    return (design['slides'] as List).map((s)=>{...learningCopy(learningMap(s)),'title':'AI: ${s['title']}'}).toList();
  }
  @override
  Future<Map<String,dynamic>> read(String owner,String section,{String search='',int offset=0}) async {
    if(section.startsWith('drafts:')) {
      final rows=drafts.values.where((d)=>d['topic_id']==section.substring(7)).map((d)=>{...d,'content_revision':lessons[d['id']]?['revision']??0}).toList();
      return {'items':rows,'total':rows.length};
    }
    return super.read(owner,section,search:search,offset:offset);
  }
  @override
  Future<void> mutate(String owner,String operationId,String type,Map<String,dynamic> payload) async {
    if(type=='lesson.draft') {
      if((drafts[payload['id']]?['draft_revision']??0)!=payload['revision']) throw const AdminFailure('Stale draft');
      drafts[payload['id'] as String]={...learningCopy(payload),'draft_revision':(payload['revision'] as int)+1,'builder_status':'draft'};
      return;
    }
    if(type=='lesson.save'&&payload['mechanism']=='slideLesson') {
      final old=lessons[payload['id']];
      if((old?['revision']??0)!=payload['revision']) throw const AdminFailure('Stale content');
      lessons[payload['id'] as String]={...learningCopy(payload),'activity_id':payload['id'],'content_version':(old?['content_version'] as int? ?? 0)+1,
        'evaluator_version':4,'mechanism_version':1,'hint_levels':[payload['hint']],'initial_state':initialSlideState(payload['config'] as Map),
        'position':payload['sort_order'],'editor_status':payload['status'],'revision':(payload['revision'] as int)+1};
      drafts[payload['id']]!['builder_status']='published';release++;return;
    }
    return super.mutate(owner,operationId,type,payload);
  }
}

Map<String,dynamic> fourEngineConfig()=>{'schema_version':1,'slides':[for(final engine in ['story','quiz','pairs','graph'])newLessonSlide(engine)]};
Map<String,dynamic> slideWire(Map<String,dynamic> config)=>{'activity_id':'cms-slides','title':'CMS slides','prompt':'Khám phá','hint_levels':['Đọc yêu cầu'],
  'stage':'Khám phá','explanation':'Hoàn thành','mechanism':'slideLesson','evaluator_version':4,'content_version':1,'config':config};

void main(){
  test('all four engine contracts reject malformed configuration and evaluate independently',(){
    final c=fourEngineConfig();expect(validSlideLesson(c),true);
    final spec=decodeAuthoredLesson(slideWire(c))!;
    final state=spec.initialData();expect(spec.isCorrect(state),false);
    final rows=state['slides'] as List;
    rows[0]={'ack':true};rows[1]={'answer':0};rows[2]={'values':[0,1]};rows[3]={'a':2,'b':1};
    expect(spec.isCorrect(state),true);
    for(final wrong in [null,'2',2.1,-99]) {rows[3]={'a':wrong,'b':1};expect(spec.isCorrect(state),false);}
    rows[3]={'a':2,'b':1};rows[2]={'values':[0,0]};expect(spec.isCorrect(state),false);
    final invalid=learningCopy(c);invalid['slides'][3]['config']['max_a']=-5;expect(validSlideLesson(invalid),false);
    final badImage=learningCopy(c);badImage['slides'][0]['config']['image_url']='javascript:alert(1)';expect(validSlideLesson(badImage),false);
    final unknown=learningCopy(c);unknown['slides'][1]['engine']='execute-code';expect(validSlideLesson(unknown),false);
    expect(validSlideLesson({'schema_version':1,'slides':[newLessonSlide('story')]}),false);
  });

  for(final engine in slideEngineNames.keys){
    testWidgets('$engine shared engine is usable at 320 px and large text',(tester) async {
      tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,1000);
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue=1.4;addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final slide=newLessonSlide(engine);
      var state=learningMap((initialSlideState({'slides':[slide]})['slides'] as List).first);
      await tester.pumpWidget(MaterialApp(theme:buildAppTheme(),home:Scaffold(body:SingleChildScrollView(padding:const EdgeInsets.all(16),child:StatefulBuilder(builder:(context,refresh)=>SlideEngineWorkspace(slide:slide,state:state,locked:false,onChanged:(s)=>refresh(()=>state=s)))))));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
      if(engine=='quiz'){await tester.tap(find.byKey(const ValueKey('slide-answer-0')));await tester.pump();expect(state['answer'],0);}
      if(engine=='story'){await tester.tap(find.byType(CheckboxListTile));await tester.pump();expect(state['ack'],true);}
      if(engine=='pairs'){
        final feedback=find.text('1/2').first;
        final target=find.byType(DragTarget<int>).first;
        await tester.drag(feedback,tester.getCenter(target)-tester.getCenter(feedback));await tester.pumpAndSettle();expect((state['values'] as List).first,0);
      }
      if(engine=='graph'){
        final slider=find.byKey(const ValueKey('slide-slider-a'));
        await tester.drag(slider,const Offset(40,0));await tester.pumpAndSettle();expect(state['a'],isNot(0));
      }
      expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('web studio designs slides, preserves engine selection through AI, saves drafts and publishes to mobile catalog',(tester) async {
    tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(1700,1100);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final auth=TestAdminAuth(),repo=StudioTestRepository();
    repo.topics.add(const AdminTopic(id:'cms-topic',title:'CMS topic',subtitle:'',subject:'QA',status:'active',sortOrder:0).toPayload());
    final controller=AdminDashboardController(auth:auth,repository:repo);
    await tester.pumpWidget(AdminApp(controller:controller));await tester.pumpAndSettle();controller.selectSection('builder');await tester.pumpAndSettle();
    Future<void> tap(Finder f) async {
      if(f.evaluate().isEmpty) {await tester.scrollUntilVisible(f,300,scrollable:find.byType(Scrollable).at(1));}
      await tester.ensureVisible(f.first);await tester.pumpAndSettle();await tester.tap(f.first);await tester.pumpAndSettle();
    }
    await tap(find.byKey(const ValueKey('studio-new')));
    await tester.enterText(find.byKey(const ValueKey('builder-title')),'Bài học do admin thiết kế');await tester.pumpAndSettle();
    for(final engine in ['graph','pairs','quiz']) {
      await tap(find.byKey(const ValueKey('builder-add-slide')));await tap(find.text(slideEngineNames[engine]!).last);
    }
    final ai=find.byKey(const ValueKey('builder-ai-prompt'));
    if(ai.evaluate().isEmpty){await tester.scrollUntilVisible(ai,300,scrollable:find.byType(Scrollable).at(1));}
    await tester.ensureVisible(ai);await tester.enterText(ai,'Soạn một bài học dễ hiểu cho học sinh lớp 4, giữ cấu trúc các engine đã chọn.');await tester.pumpAndSettle();
    await tap(find.byKey(const ValueKey('builder-generate')));
    expect((repo.generatedDesign!['slides'] as List).map((s)=>s['engine']),['story','graph','pairs','quiz']);
    expect(repo.lessons,isEmpty);
    await tap(find.byKey(const ValueKey('builder-save')));expect(repo.drafts.length,1);
    await tap(find.byKey(const ValueKey('builder-publish')));expect(repo.lessons.length,1);
    final catalog=decodeMobileCatalog(repo.catalog);expect(catalog.single.experiments.single.mechanism,'slideLesson');
    expect((catalog.single.experiments.single.config['slides'] as List).length,4);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());controller.dispose();await auth.events.close();await repo.events.close();await repo.catalogEvents.close();
  });
}
