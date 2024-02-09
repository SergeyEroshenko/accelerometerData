//
//  ViewController.swift
//  accelerometerData
//
//  Created by Сергей Ерошенко on 02.09.2021.
//  При поддержки ООО "ИСКИТИМСКИЕ РЕШЕНИЯ" 28/08/2023
//
import CoreMotion
import UIKit

class ViewController: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var gyrox: UILabel!
    @IBOutlet weak var gyroy: UILabel!
    @IBOutlet weak var gyroz: UILabel!
    @IBOutlet weak var accela: UILabel!
    @IBOutlet weak var accely: UILabel!
    @IBOutlet weak var accelz: UILabel!
    
    var isRecording = false
    var motion = CMMotionManager()
    var frameRate = 1.0 / 30.0
    var fileHandle: FileHandle!
    var fileName: String = ""
    var fileURL: URL?
    
    var shouldWriteToCsv = false
    var isGyroUpdated = false
    var isAccelUpdated = false
    var isGravityUpdated = false
    
    
    var gyroxData: String = ""
    var gyroyData: String = ""
    var gyrozData: String = ""
    var accelaData: String = ""
    var accelyData: String = ""
    var accelzData: String = ""
    var gravxData: String = ""
    var gravyData: String = ""
    var gravzData: String = ""

    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        isRecording.toggle()
        
        if isRecording {
            sender.setTitle("STOP", for: .normal)

            //fileName = "\(Date()).csv"
            
            // Получение текущего времени с учетом часового пояса устройства
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current
            let currentDateTimeString = dateFormatter.string(from: Date())
            
            // Заменим недопустимые символы в строке времени, чтобы использовать его в качестве имени файла
            let validFileName = currentDateTimeString.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")
            
            fileName = "\(validFileName).csv"
            
            let csvHeader = "ts,gyrox,gyroy,gyroz,accelx,accely,accelz,gravx,gravy,gravz\n"
            //let csvHeader = "Gyro-X,Gyro-Y,Gyro-Z,Accel-X,Accel-Y,Accel-Z\n"
            let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
            do {
                try csvHeader.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
                fileHandle = try FileHandle(forWritingTo: filePath)
            } catch {
                print("Failed to create file: \(error.localizedDescription)")
            }
            
            // Сбрасываем флаги
            isGyroUpdated = false
            isAccelUpdated = false
            isGravityUpdated = false
            
        } else {
            sender.setTitle("Record", for: .normal)
            
            fileHandle?.closeFile()
            
            // Показать UIDocumentPickerViewController для экспорта файла
            if let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                let documentPicker = UIDocumentPickerViewController(forExporting: [filePath])
                documentPicker.delegate = self
                self.present(documentPicker, animated: true, completion: nil)
            }
        }
    }
    
    
    func showDocumentPicker() {
        if let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            let documentPicker = UIDocumentPickerViewController(forExporting: [filePath])
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

        guard let url = urls.first else { return }
        
        self.fileURL = url
        // Дополнительные действия после выбора директории для экспорта
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MyGyro()
        MyAccel()
        MyGravity()
    }
    
    func MyGyro() {

        motion.gyroUpdateInterval = frameRate
        motion.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
            if let gyroData = data {
                let gyroxData = gyroData.rotationRate.x
                let gyroyData = gyroData.rotationRate.y
                let gyrozData = gyroData.rotationRate.z
                
                // Сохранение данных в переменные класса
                self.gyroxData = String(format: "%.4f", gyroxData)
                self.gyroyData = String(format: "%.4f", gyroyData)
                self.gyrozData = String(format: "%.4f", gyrozData)
                
                self.gyrox.text = self.gyroxData
                self.gyroy.text = self.gyroyData
                self.gyroz.text = self.gyrozData


                // Устанавливаем флаги внутри этого блока
                self.isGyroUpdated = true  // Устанавливаем флаг
                self.shouldWriteToCsv = self.isGyroUpdated
                    && self.isAccelUpdated && self.isGravityUpdated
                // Проверяем, нужно ли записывать данные
                
                // Запись в CSV, если isRecording = true
                self.writeToCsv()
            }
        }
    }

    func MyAccel() {
        motion.accelerometerUpdateInterval = frameRate
        motion.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let accelData = data {
                let accelaData = accelData.acceleration.x
                let accelyData = accelData.acceleration.y
                let accelzData = accelData.acceleration.z
    
                self.accelaData = String(format: "%.4f", accelaData)
                self.accelyData = String(format: "%.4f", accelyData)
                self.accelzData = String(format: "%.4f", accelzData)
                
                self.accela.text = self.accelaData
                self.accely.text = self.accelyData
                self.accelz.text = self.accelzData
                
                // Устанавливаем флаги внутри этого блока
                self.isAccelUpdated = true  // Устанавливаем флаг
                self.shouldWriteToCsv = self.isGyroUpdated
                && self.isAccelUpdated && self.isGravityUpdated
                //Проверяем, нужно ли записывать данные
                
                // Запись в CSV, если isRecording = true
                self.writeToCsv()
            }
        }
    }
    
    func MyGravity() {
        motion.deviceMotionUpdateInterval = frameRate
        motion.startDeviceMotionUpdates(to: OperationQueue.current!) { (data, error) in
            if let motionData = data {
                let gravityData = motionData.gravity

                self.gravxData = String(format: "%.4f", gravityData.x)
                self.gravyData = String(format: "%.4f", gravityData.y)
                self.gravzData = String(format: "%.4f", gravityData.z)
                
                self.isGravityUpdated = true  // Устанавливаем флаг
                self.shouldWriteToCsv = self.isGyroUpdated
                 && self.isAccelUpdated && self.isGravityUpdated
                // Проверяем, нужно ли записывать данные
                
                // Запись в CSV, если isRecording = true
                self.writeToCsv()
            }
        }
    }

    func writeToCsv() {
        if isRecording && shouldWriteToCsv {

            //with time
            let time = String(format: "%.3f", Date().timeIntervalSince1970)
            let cast = [
                time, gyroxData, gyroyData, gyrozData,
                accelaData, accelyData, accelzData,
                gravxData, gravyData, gravzData
            ]
            let csvRow = cast.joined(separator: ",") + "\n"
            //without time
            //let csvRow = String(format: "%.6f,%.6f,%.6f, %.6f,%.6f,%.6f\n", gyroxData, gyroyData, gyrozData, accelaData, accelyData, accelzData)
            
            //if let data = csvRow.data(using: .utf8) {
            //    fileHandle?.write(data)
            //}
            if let data = csvRow.data(using: .utf8) {
                fileHandle?.seekToEndOfFile()  // Перемещаем указатель записи на конец файла
                fileHandle?.write(data)        // Записываем данные
            }

            
            // Сбрасываем флаги
            isGyroUpdated = false
            isAccelUpdated = false
            shouldWriteToCsv = false

        }
    }

    
}
