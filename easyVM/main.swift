//
//  main.swift
//  easyVM
//
//  Created by clivebi on 2022/3/2.
//
import Darwin
import Foundation
import Virtualization

enum Signal: Int32 {
    case HUP    = 1
    case INT    = 2
    case QUIT   = 3
    case ABRT   = 6
    case KILL   = 9
    case ALRM   = 14
    case TERM   = 15
}

func handle_signal(signal: Int32, action:@escaping @convention(c) (Int32) -> ()) {
    typealias SignalAction = sigaction
    
    var signalAction = SignalAction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
    _=withUnsafePointer(to: &signalAction) { ptr in
        sigaction(signal,ptr,nil)
    }
}
var confFile:String = "./easyVM.json"
if (CommandLine.argc == 2){
    confFile = String(cString: CommandLine.unsafeArgv[1]!)
}
let config = VMConfig.fromFile(file: confFile)
if !config.isValid{
    print("load config file failed:\(confFile)")
    print("easyVM config file path (default:./easyVM.json)")
    exit(0)
}
let controller = VMController(conf: config)

class VMStateWatcher:VMControllerDelegate{
    func didVMStateChanged(vm: VMController, state: VZVirtualMachine.State) {
        if(state == .error || state == .stopped){
            print("+++ VM Stoped")
            exit(0)
        }
    }
}

controller.start { ok in
    if(!ok){
        exit(0)
    }else{
        controller.delegate = VMStateWatcher()
        handle_signal(signal: 2) { c in
            controller.stop { err in
                exit(0)
            }
        }
    }
}
CFRunLoopRun()

