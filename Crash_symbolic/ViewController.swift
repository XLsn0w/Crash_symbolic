//
//  ViewController.swift
//  Crash_symbolic
//
//  Created by HL on 2018/7/11.
//  Copyright © 2018年 XL. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

}

