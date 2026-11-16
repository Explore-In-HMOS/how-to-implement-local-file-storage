import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppConstants } from '../common/AppConstants';
import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { NoteListView } from '../view/NoteListView';
import { NoteDetailPage } from '../view/NoteDetailPage';
import { StoragePage } from '../view/StoragePage';

@Entry
@ComponentV2
struct Index {
  @Local pathStack: NavPathStack = new NavPathStack();
  // AppStorageV2 gives every page the same ViewModel instance.
  @Local vm: NotesViewModel =
    AppStorageV2.connect(NotesViewModel, AppConstants.VM_KEY, () => new NotesViewModel())!;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.vm.init(context);
    this.vm.load();
  }

  @Builder
  routeMap(name: string, param: Object) {
    if (name === AppConstants.ROUTE_DETAIL) {
      NoteDetailPage({ fileName: param as string })
    } else if (name === AppConstants.ROUTE_STORAGE) {
      StoragePage()
    }
  }

  build() {
    Navigation(this.pathStack) {
      NoteListView({
        vm: this.vm,
        onOpenNote: (fileName: string) => {
          this.pathStack.pushPathByName(AppConstants.ROUTE_DETAIL, fileName);
        },
        onOpenStorage: () => {
          this.pathStack.pushPathByName(AppConstants.ROUTE_STORAGE, '');
        }
      })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
    .navDestination(this.routeMap)
  }
}
