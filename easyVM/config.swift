//
//  config.swift
//  easyVM
//
//  Created by clivebi on 2022/3/2.
//

import Foundation
import Virtualization

class VMConfig{
    static let KB:Int=1024
    static let MB:Int=1024*1024
    static let GB:Int=1024*1024*1024
    
    fileprivate static func stringToSize(text:String)->Int{
        let search = text.uppercased()
        var number:Substring = ""
        var base:Int = 1
        if(search.hasSuffix("KB")){
            number = search.prefix(search.count-2)
            base = KB
        }else if(search.hasSuffix("MB")){
            number = search.prefix(search.count-2)
            base = MB
        }else if(search.hasSuffix("GB")){
            number = search.prefix(search.count-2)
            base = GB
        }else{
            number = search.prefix(search.count)
        }
        for v in number{
            if !v.isNumber{
                return 0
            }
        }
        return (Int(String(number)) ?? 0)*base
    }
    static func fromFile(file:String)->VMConfig{
        let vm = VMConfig()
        guard let data = NSData(contentsOfFile: file) as Data? else{
            return vm
        }
        do{
            guard let map = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] else{
                return vm
            }
            if let n = map["name"] as? String{
                vm.mName = n
            }
            if let cd = map["cdrom"] as? [String]{
                vm.mCDImage = cd
            }
            if let disk = map["disk"] as? [String]{
                vm.mDiskImage = disk
            }
            if let shared = map["shared"] as? [[String]] {
                for v in shared{
                    if(v.count == 2){
                        vm.mSharedFolder.append(v)
                    }
                }
            }
            if let cpu = map["cpu"] as? Int{
                vm.mCPU = cpu
            }
            if let memory = map["memory"] as? String{
                vm.mMemory = stringToSize(text: memory)
            }
            if let kernel = map["kernel"] as? String{
                vm.mKernel = kernel
            }
            if let ramdisk = map["initrd"] as? String{
                vm.mRamDisk = ramdisk
            }
            if let cmd = map["commandline"] as? String{
                vm.mCommandLine = cmd
            }
        }catch{
            return vm
        }
        return vm
    }
    
    func toJSON()->Data?{
        let obj = ["name":self.mName,
                   "cdrom":self.mCDImage,
                   "disk":self.mDiskImage,
                   "shared":self.mSharedFolder,
                   "cpu":self.mCPU,
                   "memory":String(mMemory),
                   "kernel":mKernel,
                   "initrd":mRamDisk,
                   "commandline":mCommandLine
        ] as [String : Any]
        return try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
    }
    
    func show_shared_mount_command_line(){
        if mSharedFolder.isEmpty{
            return
        }
        print("+++ please use this command to mout all you shared folder...")
        var i = 0
        for v in mSharedFolder{
            let name = "easyVMShared\(i)"
            print("mkdir -p \(v[1])")
            print("mount -t virtiofs \(name) \(v[1])")
            i+=1
        }
    }
    
    
    var isValid: Bool {
        if(mCDImage.isEmpty && mDiskImage.isEmpty){
            return false
        }
        if(mCPU == 0 || mMemory == 0){
            return false
        }
        if(mKernel.isEmpty&&mRamDisk.isEmpty){
            return false
        }
        return true
    }
    var mName:String = ""
    var mCDImage:[String] = []
    var mDiskImage:[String] = []
    var mSharedFolder:[[String]] = []
    var mCPU:Int = 0
    var mMemory:Int = 4*VMConfig.GB
    var mKernel:String = ""
    var mRamDisk:String = ""
    var mCommandLine = ""
}
