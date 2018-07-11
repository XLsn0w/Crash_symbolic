/*那么，第一个问题，我们要做的是什么？
通俗点说就是我们需要做上哪些新功能，达到哪些目标。
这是我在动手之前思考的一个问题，先明确需求，要做哪些新功能，有目标的去找解决方案。
这方面我列了几条

解决类型不同的转换问题
解决泛型Array的赋值问题（Array<XXModel>）
父类和父类的父类赋值问题，往前递归几层？是否做限制？
过滤Foundation框架里的属性
明确了问题之后就可以找解决方案了，首先在OC下由于有强大牛逼的runtime和完善的Foundation的API，这几个问题都不是问题，不过还是记录一下吧：

类型不同的转换问题：解决这个问题要单独把不同类型拉出来，如果是数字类型转string，可以直接取stringValue，也可以直接stringWithFormat，如果是string转数字类型，则可以统一用NSNumberFormatter处理，转成NSNumber即可
泛型Array的赋值问题，runtime可以上场了，先获取当前class的所有属性，拿到objc_property_t类型，property_getAttributes这个API拿到的字符串中是包含NSArray<XXXModel>这种泛型字段的，直接把NSArray的元素类型截出来，再转换成Class对象就可以了。
父类的问题，这里我思考了很久，网上几个库的解决方案不一样，有的是直接递归到NSObject层，再在属性筛选的时候把系统API给去掉，有的是在递归的时候加个判断，递归到Foundation的时候就break，我比较了一下觉得后者性能更好，减少了递归次数，但是没有实验的地方是如果子类override了Foundation框架中的属性会怎么样，不过这么做的情况也很少，我也就暂时忽略掉了。
Foundation属性的过滤，这个在上一层父类递归的时候就已经筛选掉了，因为不会递归到Foundation的类上面去，自然也不会出现Foundation的属性。
刚才说的是OC的方案，也就是使用runtime的方案，那么在swift下这个方案可不可行呢？
我实验了一下，Swift中的原生Array在property_getAttributes这个可以获取泛型的API拿到的类型是NSArray，同时NSArray在这个API下拿到的也是NSArray，区分不开，好了，那我就抛弃runtime找找其他的解决方案吧。

首先找到的库是Reflection，这个库很吊很牛逼，牛逼到我现在还没完全看懂它的代码（当然是我太菜了），里面大概的思路是拿到Swift下面的类的C指针，然后对指针去做偏移，从而动态拿到这个类的属性的一系列信息，这个库我看了下确实满足了我所有需求，但是秉持着作死的精神，我还是想自己找到一个看得懂的解决方案出来。

第二个库是GrandModel，这个整体的方案和我之前的方案大致相似：通过Mirror动态拿属性列表，拿完之后用NSObject的setValue(_:forKey:)去做赋值，那看来我的方案是可以实现我的需求的！那就这么做了！

由于加入了Swift的原生类型，所以不能用Foundation框架里的API去做了，我想到的方案是Mirror的subjectType可以拿到当前类的类型，那么我就需要遍历当前类的所有property，对每个value取mirror，去拿类型再存起来。

类型转换问题，数字类型转String，直接走"\(value)"，这个简单，string转数字这个需要对每个数字类型进行判断，如果是Int要调Int的init，如果是Double要调double的init，这个还有优化空间。
泛型Array的处理，通过Mirror拿到的subjectType也是包含元素类型的信息的，由于swift的所有Array和Dictionary必须要注明元素类型，所以我这里要做一个分支处理：如果Array的元素类型是Model，而且实际从服务端传入的value也是[String:Any]的情况下才进行Array的遍历KVC，如果上面的条件不满足，那么就要判断类Array的元素类型和服务端value的元素类型是否一致，如果不一致直接赋值会有crash风险，核心代码如下：
if valueType.hasPrefix("Array") {
    let arrayClassName = valueType.substring(with: valueType.index(valueType.startIndex, offsetBy: 6)..<valueType.index(valueType.endIndex, offsetBy: -1));
    if arrayClassName.hasPrefix("Dictionary<String") {
        if property.arrayClass != nil && property.arrayClass == .item {
            ret = type(of: self).itemsWithArray(value as! Array<Dictionary<String, Any>>);
        } else  {
            //arrayClass不是item，无需作数组泛型KVC，直接赋值，此处有因为Dictionary的泛型不一致导致的crash风险，待处理
            ret = value;
        }
    } else {
        ret = value;
    }
}
父类的处理，我这里直接抛弃了Swift原生类型的继承的处理，我觉得自己继承Array去写一个类的情况也比较少，就简单处理了，沿用上面OC的处理就行了，只是OC取父类是用runtime的API，Swift里我用的是superMirror。
Foundation属性的过滤，这一条和OC处理方法一致，在父类递归取属性的时候，如果父类的类型以NS开头，就直接break就行了。

*/
import UIKit

class Item: NSObject {///这是因为KVC是OC 的方法，OC方法和属性都需要运行时写到类对象中，swift 利用KVC设置属性需要运行时机制，swift4.0以前，编译器默认帮我们做了在对象声明前加上了@objc，4.0需要手动加上。
    
    //MARK : 存储属性
    @objc var  access_token:String = ""
    @objc var  expires_in:TimeInterval = 0.0
    @objc var  uid:String?
    
    func autoKVCBinding(_ dictionary:Dictionary<String, Any>?) {///单纯只做了空值校验，property如果还是同名model的话可以做递归的KVC校验。
        if dictionary != nil {
            let mirror:Mirror = Mirror(reflecting: self);
            for (label,value) in mirror.children {
                if label != nil && dictionary![label!] != nil {
                    if value is Item && dictionary![label!] is Dictionary<String, Any> {
                        let subItem = value as! Item;
                        subItem.autoKVCBinding(dictionary![label!] as? Dictionary<String, Any>);
                    } else {
                        self.setValue(dictionary![label!], forKey: label!);
                    }
                }
            }
        }
    }
    
}


    /*
     在Swift中使用KVC分为3中情况:
     (1)在swift3.0之前，类必须要继承自NSObject,因为KVC是OC的东西
     (2)在Swift4.0之后，类必须要继承自NSObject,同时还需要在属性前面加上@objc
     在Swift4.0之前,编译器会默认帮我们在对象属性前面加上@objc
     在Swift里，有一种间接访问类属性的方法，叫做#keyPath
     
     class Person : NSObject {
     @objc var name:String = ""
     init(dict:[String:Any]){
     super.init()
     setValuesForKeys(dict)
     }
     }
     let p1 = Person(dict: ["name":"lichangan"])
     let name = p1.value(forKeyPath: #keyPath(Person.name))
     print(name) //lichangan
     p1.setValue("shuaige", forKeyPath: #keyPath(Person.name))
     print(p1.name) //shuaige
     
     这就是Cocoa中的KVC机制，在Objective-C中它可以很好的工作，但移植到Swift之后，它的不足就显现出来了：
     value(forKeyPath:)方法返回的类型是Any?，这样我们就失去了类型信息，错误的赋值会直接导致运行时错误；
     只有NSObject的派生类才支持这种访问机制
     
     (3)Swift 4中设计了更智能的KeyPath
     
     class Person {
     var name:String = ""
     init(name:String){
     self.name = name;
     }
     }
     
     let p2 = Person(name:"lichangan")
     let nameKeyPath = \Person.name
     let name = p2[keyPath:nameKeyPath]
     print(name) //lichangan
     p2[keyPath:nameKeyPath] = "shuaige"
     print(p2.name) //shuaigei
     
     \Person.name 就是Swift4中新的key path用法，他是一个独立的类型，带有类型的信息。
     因此，编译器会发现错误类型的赋值，因此不会把这个错误延迟到运行时
     
     除了类型安全之外，新的KeyPath不需要继承自NSObject,也不需要使用@obj修饰属性，同时struct也可以使用新的KeyPath
     

     
    */

