//
//  atos.swift
//  Crash_symbolic
//
//  Created by HL on 2018/7/11.
//  Copyright © 2018年 XL. All rights reserved.
//


///atos实际是一个可以把地址转换为函数名（包括行号）的工具，atos 语法：atos -o dysm文件路径 -l 模块load地址 调用方法的地址，上面的0x182274000就是模块load地，0x0000000182399900就是调用方法的地址。

/*
一、场景
客户端的开发流程都相似，如android，搞ios开发就要不停地发版本，随之而来的就是各种版本的崩溃日志（称为crash log）。如果不能好好地管理，那么开发人员很快就会在crash log和版本的海洋里迷失方向。解决崩溃问题是移动应用开发者最日常的工作之一。如果是开发过程中遇到的崩溃，可以根据重现步骤调试，但线上版本就无能为力了。

国内，一般的公司是没有对ios crash符号化分析系统的，能够对ios 的crash日志做符号化做得好的公司比较少，比较好的是 “腾讯bugly”，链接：http://bugly.qq.com 。ios的日志分析，做符号化，并定位到发生崩溃的原因，对app的开发百利无一害，功德无量。

关注问题本身，客户端开发和后台服务开发管理日志有很大的不同：

如果是服务器报了个异常，对于java的服务，RD登上机器，看看错误的日志，看到“crash by...” 找出原因，改代码，重新编译打包部署一下就算修复了，假如是分布式的集群，服务是可以不间断的提供服务的。

如果是客户端开发，在实际的项目开发中，崩溃问题，依赖xcode编辑器，依赖于系统记录的崩溃日志或错误堆栈，在本地开发调试阶段，是没有问题的。如果在发布的线上版本出现崩溃问题，开发者是无法即时准确的取得错误堆栈的。需要适当的时期将crash上报到服务端，由服务端处理收集分析。客户端需要重新发版才能修复旧版的crash。


 demo 原始crash日志：
 

 
 ### 1.进程信息 ###
 Incident Identifier: 87164E05-84A8-40F2-886D-14F90C9D3F47
 CrashReporter Key:   TODO
 Hardware Model:      iPhone7,2
 Process:         imeituan [945]
 Path:            /var/mobile/Containers/Bundle/Application/96DC918D-60C8-4C49-A51D-C0D71D0FCB4D/imeituan.app/imeituan
 Identifier:      com.meituan.imeituan
 Version:         895
 Code Type:       ARM-64
 Parent Process:  ??? [1]
 
 ### 2.基本信息 ###
 Date/Time:       2016-02-01 16:14:24 +0000
 OS Version:      iPhone OS 9.2.1 (13D15)
 Report Version:  104
 
 ### 3.异常信息 ###
 Exception Type:  SIGABRT
 Exception Codes: #0 at 0x181f3c140
 
 ### 4.线程回溯 ###
 Crashed Thread:  0
 Application Specific Information:
 *** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[__NSArrayM objectAtIndex:]: index 25 beyond bounds [0 .. 24]'
 
 ### 5.Crash调用堆栈，需要需要将堆栈的二进制转成可读的###
 Last Exception Backtrace:
 0   CoreFoundation                      0x0000000182399900 0x182274000 + 1202432
 1   libobjc.A.dylib                     0x0000000181a07f80 0x181a00000 + 32640
 2   CoreFoundation                      0x000000018227f828 0x182274000 + 47144
 3   imeituan                            0x0000000101ab593c 0x1000b8000 + 27253052
 4   imeituan                            0x0000000100521a68 0x1000b8000 + 4627048
 5   UIKit                               0x00000001873dd31c 0x187078000 + 3560220
 6   UIKit                               0x00000001873dd484 0x187078000 + 3560580
 7   UIKit                               0x00000001873cc7e8 0x187078000 + 3491816
 8   UIKit                               0x00000001873e1fb0 0x187078000 + 3579824
 9   UIKit                               0x000000018717708c 0x187078000 + 1044620
 10  UIKit                               0x0000000187087778 0x187078000 + 63352
 11  QuartzCore                          0x0000000184a96b2c 0x184a88000 + 60204
 12  QuartzCore                          0x0000000184a91738 0x184a88000 + 38712
 13  QuartzCore                          0x0000000184a915f8 0x184a88000 + 38392
 14  QuartzCore                          0x0000000184a90c94 0x184a88000 + 35988
 15  QuartzCore                          0x0000000184a909dc 0x184a88000 + 35292
 16  QuartzCore                          0x0000000184a8a0cc 0x184a88000 + 8396
 17  CoreFoundation                      0x0000000182350588 0x182274000 + 902536
 18  CoreFoundation                      0x000000018234e32c 0x182274000 + 893740
 19  CoreFoundation                      0x000000018234e75c 0x182274000 + 894812
 20  CoreFoundation                      0x000000018227d680 0x182274000 + 38528
 21  GraphicsServices                    0x000000018378c088 0x183780000 + 49288
 22  UIKit                               0x00000001870f4d90 0x187078000 + 511376
 23  imeituan                            0x0000000100112628 0x1000b8000 + 370216
 24  ???                                 0x0000000181e1e8b8 0x0 + 0
 
 …
 
 ### 6.动态库信息 ###
 Binary Images:
 0x1000b8000 -        0x10275ffff +imeituan arm64  <e38d01be571931b7a4c3d9dcbf28e821> /var/mobile/Containers/Bundle/Application/96DC918D-60C8-4C49-A51D-C0D71D0FCB4D/imeituan.app/imeituan
 0x10d76c000 -        0x10d7dbfff  AGXMetalG4P arm64  <f76b11f8d06338f99ae4704aba08111c> /System/Library/Extensions/AGXMetalG4P.bundle/AGXMetalG4P
 0x182058000 -        0x18225dfff  libicucore.A.dylib arm64  <5c1540546de5350ab314c1d4c8a46d1b> /usr/lib/libicucore.A.dylib
 
 …
 
 0x182274000 -        0x1825ecfff  CoreFoundation arm64  <121118a9a44d3518b99f3ebfd8806f69> /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 0x1825f0000 -
 

 /// handle
 主要有6部分组成:
 
 1.进程信息
 2.基本信息
 3.异常信息
 4.线程回溯
 5.Crash调用堆栈（全是地址信息，需要使用符号表转成可读的）
 6.动态库信息（第5部分依赖的库）
 ios的符号化也主要是根据第5和第6部分进行符号化，只有把第五部分后面的二进制的地址信息映射成代码信息，才能发生crash的原因。
 
 下面是上面的crash日志符号化后的结果：
 

 ### 1.进程信息 ###
 Incident Identifier: 87164E05-84A8-40F2-886D-14F90C9D3F47
 CrashReporter Key:   TODO
 Hardware Model:      iPhone7,2
 Process:         imeituan [945]
 Path:            /var/mobile/Containers/Bundle/Application/96DC918D-60C8-4C49-A51D-C0D71D0FCB4D/imeituan.app/imeituan
 Identifier:      com.meituan.imeituan
 Version:         895
 Code Type:       ARM-64
 Parent Process:  ??? [1]
 
 ### 2.基本信息 ###
 Date/Time:       2016-02-01 16:14:24 +0000
 OS Version:      iPhone OS 9.2.1 (13D15)
 Report Version:  104
 
 ### 3.异常信息 ###
 Exception Type:  SIGABRT
 Exception Codes: #0 at 0x181f3c140
 
 ### 4.线程回溯 ###Crashed Thread:  0
 Application Specific Information:
 *** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[__NSArrayM objectAtIndex:]: index 25 beyond bounds [0 .. 24]'
 
 ### 5.Crash调用堆栈，需要需要将堆栈的二进制转成可读的###
 Last Exception Backtrace:
 0   CoreFoundation                      __exceptionPreprocess + 124
 1   libobjc.A.dylib                     objc_exception_throw + 56
 2   CoreFoundation                      -[__NSArrayM removeObjectAtIndex:] + 0
 3   imeituan                            -[SAKFetchedResultsController objectAtIndexPath:] (SAKFetchedResultsController.m:60)
 4   imeituan                            -[DEFHomePageViewController tableView:cellForRowAtIndexPath:] (DEFHomePageViewController.m:663)
 5   UIKit                               -[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] + 692
 6   UIKit                               -[UITableView _createPreparedCellForGlobalRow:willDisplay:] + 80
 7   UIKit                               -[UITableView _updateVisibleCellsNow:isRecursive:] + 2360
 8   UIKit                               -[UITableView _performWithCachedTraitCollection:] + 104
 9   UIKit                               -[UITableView layoutSubviews] + 176
 10  UIKit                               -[UIView(CALayerDelegate) layoutSublayersOfLayer:] + 656
 11  QuartzCore                          -[CALayer layoutSublayers] + 148
 12  QuartzCore                          CA::Layer::layout_if_needed(CA::Transaction*) + 292
 13  QuartzCore                          CA::Layer::layout_and_display_if_needed(CA::Transaction*) + 32
 14  QuartzCore                          CA::Context::commit_transaction(CA::Transaction*) + 252
 15  QuartzCore                          CA::Transaction::commit() + 512
 16  QuartzCore                          CA::Transaction::observer_callback(__CFRunLoopObserver*, unsigned long, void*) + 80
 17  CoreFoundation                      __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 32
 18  CoreFoundation                      __CFRunLoopDoObservers + 372
 19  CoreFoundation                      __CFRunLoopRun + 928
 20  CoreFoundation                      CFRunLoopRunSpecific + 384
 21  GraphicsServices                    GSEventRunModal + 180
 22  UIKit                               UIApplicationMain + 204
 23  imeituan                            main (main.m:34)
 24  ???                                 0x0000000181e1e8b8 0x0 + 0
 ### 6.动态库信息 ###
 Binary Images:
 0x1000b8000 -        0x10275ffff +imeituan arm64  <e38d01be571931b7a4c3d9dcbf28e821> /var/mobile/Containers/Bundle/Application/96DC918D-60C8-4C49-A51D-C0D71D0FCB4D/imeituan.app/imeituan
 0x10d76c000 -        0x10d7dbfff  AGXMetalG4P arm64  <f76b11f8d06338f99ae4704aba08111c> /System/Library/Extensions/AGXMetalG4P.bundle/AGXMetalG4P
 0x182058000 -        0x18225dfff  libicucore.A.dylib arm64  <5c1540546de5350ab314c1d4c8a46d1b> /usr/lib/libicucore.A.dylib
 
 …
 0x182274000 -        0x1825ecfff  CoreFoundation arm64  <121118a9a44d3518b99f3ebfd8806f69> /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 0x1825f0000 -
 …

 
 
 
 ///
 例如，我们用上面的例子，从上面原始日志的第5部分挑出crash的地址，崩溃问题的函数地址堆栈如下：
 
 Last Exception Backtrace:
 0   CoreFoundation                      0x0000000182399900 0x182274000 + 1202432
 1   libobjc.A.dylib                     0x0000000181a07f80 0x181a00000 + 32640
 2   CoreFoundation                      0x000000018227f828 0x182274000 + 47144
 第一步：从第6部分找出所依赖的动态库的地址
 
 “CoreFoundation”的动态库是“/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation”：
 
 0x182274000 -        0x1825ecfff  CoreFoundation arm64  <121118a9a44d3518b99f3ebfd8806f69> /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 第二步：在符号表的该目录下验证uuid是不是对应上
 
 执行命令dwarfdump --uuid 来验证：
 
 执行命令：
 dwarfdump --uuid /Users/jenkins/data/apps/OSSDKSymbols/9.2.1\ \(13D15\)/Symbols/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 
 输出：
 UUID: 121118A9-A44D-3518-B99F-3EBFD8806F69 (arm64) /Users/jenkins/data/apps/OSSDKSymbols/9.2.1 (13D15)/Symbols/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 UUID: 910B0F17-490F-3D92-9833-A9D4AADABBDB (armv7s) /Users/jenkins/data/apps/OSSDKSymbols/9.2.1 (13D15)/Symbols/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
 发现“121118A9-A44D-3518-B99F-3EBFD8806F69”和“121118a9a44d3518b99f3ebfd8806f69”是吻合的（忽略大小写和‘－’），说明这个crash是在该版本中的。可以进行下面的符号化操作。
 
 第三步：用atos工具进行符号化
 
 atos实际是一个可以把地址转换为函数名（包括行号）的工具，atos 语法：atos -o dysm文件路径 -l 模块load地址 调用方法的地址，上面的0x182274000就是模块load地，0x0000000182399900就是调用方法的地址。
 
 例如执行命令：
 
 执行命令：
 atos -o /Users/jenkins/data/apps/OSSDKSymbols/9.2.1\ \(13D15\)/Symbols/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation -l 0x182274000 0x0000000182399900
 
 输出：
 __exceptionPreprocess (in CoreFoundation) + 124
 发现输出的结果是：__exceptionPreprocess (in CoreFoundation) + 124，说明符号化成功
 
 至此符号就成功了，这个例子只是ios的os的crash日志符号化，还有就是app层面crash，上面全部的的符号化的结果都是根据这几个步骤来完成的。
 
 
 
 上面的符号化可以知道，我们需要"dwarfdump" 和 “atos” 命令，这是mac os 上带的符号化的工具，同时还依赖xcode的版本，这是ubantu和centos系统所不支持的，所以crash log的符号化必须是在mac os上进行的，所以crash符号化服务必须在mac os进行，物理机可以是mac mini、imac或macbook。
 
 至于上面crash业务服务，可以使用一般的ubantu或centos 系统都是可以的。
 
 那么问题来了，一般来说我们发布的服务都是在ubantu或是centos系统上的，怎么把服务部署在mac os机器上呢？其实都差不多，java因为有JVM，服务是跨平台的，只是需要Runtime调用本地的“dwarfdump" 和 “atos”命令。无非就是编译、打包、部署，当然了还有初始化机器，建立发布账号，建立路径，管理服务进程等繁琐的事情，这样就可以把java服务发布到远程的mac os机器上，问题就可以解决了。
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 */
