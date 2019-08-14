import Quick
import Nimble

@testable import Mobile_Interview_Project_iOS

class ViewControllerSpec: QuickSpec {
    override func spec() {
        it("exists") {
            let subject = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController
            expect(subject).toNot(beNil())
        }
        
        
    }
}
