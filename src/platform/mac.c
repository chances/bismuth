// Referenced from this "Pure C Cocoa Application with Window and Metal" gist:
// https://gist.github.com/hasenj/1bba3ca00af1a3c0b2035c9bd14a85ef
#include <assert.h>
#include <objc/runtime.h>
#include <objc/message.h>

#define cls objc_getClass
#define sel sel_getUid

typedef id (*object_message_send)(id, SEL, ...);
typedef id (*class_message_send)(Class, SEL, ...);

#define msg ((object_message_send)objc_msgSend)
#define cls_msg ((class_message_send)objc_msgSend)

id bismuthPlatformGetMetalLayer(id window) {
  // https://developer.apple.com/documentation/quartzcore/cametallayer
  Class CAMetalLayer = cls("CAMetalLayer");
  assert(CAMetalLayer);
  id metalLayer = cls_msg(CAMetalLayer, sel("layer"));
  assert(metalLayer);
  // https://developer.apple.com/documentation/appkit/nsview?language=objc
  // https://developer.apple.com/documentation/appkit/nswindow/1419160-contentview
  id view = msg(window, sel("contentView"));
  assert(view);
  msg(view, sel("setWantsLayer:"), YES);
  assert(msg(view, sel("setLayer:"), metalLayer));
  return metalLayer;
}

// TODO: Reference the Cocoa framework for better macOS integrations?
