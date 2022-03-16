//
//  VMControl.swift
//  easyVM
//
//  Created by clivebi on 2022/3/2.
//

import Foundation
import Virtualization
import Combine

protocol VMControllerDelegate{
    func didVMStateChanged(vm:VMController,state:VZVirtualMachine.State)
}

class VMController:NSObject {
    private let mConfig:VMConfig
    private var mVM:VZVirtualMachine?
    private var cancellables: Set<AnyCancellable> = []
    var delegate:VMControllerDelegate? = nil
    init(conf:VMConfig){
        mConfig = conf
        mVM = nil
    }
    
    func start(completionHandler: @escaping (Bool)->Void){
        let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: mConfig.mKernel))
        bootloader.initialRamdiskURL = URL(fileURLWithPath: mConfig.mRamDisk)
        bootloader.commandLine = mConfig.mCommandLine
        
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        let inputFileHandle = FileHandle.standardInput
        let outputFileHandle = FileHandle.standardOutput
        
        serial.attachment = VZFileHandleSerialPortAttachment(fileHandleForReading: inputFileHandle, fileHandleForWriting: outputFileHandle)
        
        var storage:[VZStorageDeviceConfiguration] = []
        // init storage
        do{
            for v in mConfig.mCDImage{
                let block = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: v), readOnly: true)
                storage.append(VZVirtioBlockDeviceConfiguration(attachment: block))
                print("+++ add readonly storage \(v)")
            }
            for v in mConfig.mDiskImage{
                let block = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: v), readOnly: false)
                storage.append(VZVirtioBlockDeviceConfiguration(attachment: block))
                print("+++ add disk storage \(v)")
            }
            
        }catch{
            print("+++ add storage failed:\(error)")
            DispatchQueue.main.async {
                completionHandler(false)
            }
            return
        }
        
        //init shared file
        var shared:[VZVirtioFileSystemDeviceConfiguration] = []
        var i = 0
        for v in mConfig.mSharedFolder{
            let tag = "easyVMShared\(i)"
            let dir =  VZSharedDirectory(url: URL(fileURLWithPath: v[0]), readOnly: false)
            do{
                try VZVirtioFileSystemDeviceConfiguration.validateTag(tag)
            }catch{
                print("+++ valid shared directory tag failed:\(error)")
                DispatchQueue.main.async {
                    completionHandler(false)
                }
                return
            }
            print("+++ add shared directory storage \(v[0])-->\(v[1])")
            let sdir = VZSingleDirectoryShare(directory: dir)
            let vs = VZVirtioFileSystemDeviceConfiguration(tag: tag)
            vs.share = sdir
            shared.append(vs)
            i+=1
        }
        
        mConfig.show_shared_mount_command_line()
        
        let config = VZVirtualMachineConfiguration()
        config.bootLoader = bootloader
        config.cpuCount = mConfig.mCPU
        config.memorySize = UInt64(mConfig.mMemory)
        config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        config.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]
        config.serialPorts = [serial]
        config.storageDevices = storage
        config.directorySharingDevices = shared
        
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        config.networkDevices = [networkDevice]
        
        do {
            try config.validate()
            
            let vm = VZVirtualMachine(configuration: config)
            vm.delegate = self
            self.mVM = vm
            KeyValueObservingPublisher(object: vm, keyPath: \.state, options: [.initial, .new])
                .sink { [weak self] state in
                    self?.didStateChanged(state: state)
                }
                .store(in: &cancellables)
            
            vm.start { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        completionHandler(true)
                    }
                    print("+++ start VM success")
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        completionHandler(false)
                    }
                    print("+++ start VM Failed: \(error)")
                    break
                }
            }
        } catch {
            print("+++ validate config Error: \(error)")
            DispatchQueue.main.async {
                completionHandler(false)
            }
        }
    }
    
    fileprivate func didStateChanged(state:VZVirtualMachine.State){
        self.delegate?.didVMStateChanged(vm: self, state: state)
    }
    
    func stop(completionHandler: @escaping (Error?)->Void){
        cancellables = []
        guard let vm = mVM else{
            DispatchQueue.main.async {
                completionHandler(nil)
            }
            return
        }
        if(vm.canStop){
            vm.stop(completionHandler: completionHandler)
        }else{
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
}

extension VMController:VZVirtualMachineDelegate{
    
    func guestDidStop(_ virtualMachine: VZVirtualMachine){
        print("+++ VM stoped")
    }
    
    @available(macOS 11.0, *)
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error){
        print("+++ VM stoped with error:\(error)")
    }
    
    
    @available(macOS 12.0, *)
    func virtualMachine(_ virtualMachine: VZVirtualMachine, networkDevice: VZNetworkDevice, attachmentWasDisconnectedWithError error: Error){
        print("+++ VM network disconnected with error:\(error)")
    }
}
