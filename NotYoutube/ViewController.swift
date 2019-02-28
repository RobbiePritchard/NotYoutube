import UIKit


struct YoutubeResult{
    var title: String
    var thumbnailURL_medium: String
    var videoId: String
    
}
let APIKEY = "AIzaSyDgPdK9jG7fMaq8x25M4D75nLGMhwXHkec"
class ViewController: UIViewController, UISearchBarDelegate{
    
    lazy var searchBar : UISearchBar = {
        let search = UISearchBar(frame: .zero)
        search.searchBarStyle = UISearchBar.Style.minimal
        search.placeholder = " Search..."
        search.sizeToFit()
        search.delegate = self
        return search
    }()
    
    
    lazy var tableView: UITableView = {

        let table = UITableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.register(Cell.self, forCellReuseIdentifier: "Cell")
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100

        return table
    }()
    
    var results: [YoutubeResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(searchBar)
        self.view.addSubview(tableView)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setConstraints()

    }
    func setConstraints(){
        var views = [
            "searchBar": searchBar,
            "tableView": tableView
        ]
        for (key,value) in views{
            value.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[searchBar]-8-[tableView]-|", options: .alignAllCenterX, metrics: nil, views: views))
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[searchBar]-|", options: .alignAllCenterX, metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[tableView]-|", options: .alignAllCenterX, metrics: nil, views: views))

        
        self.view.layoutIfNeeded()

    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchTerm = searchBar.text ?? ""
        let youtubeApi = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(searchTerm.removeSpaces())&type=video&key=\(APIKEY)"
        let url = NSURL(string: youtubeApi)!
        getResults(from: url){ YTResults in
            self.results = YTResults
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func getResults(from url: NSURL, YTResults: @escaping (([YoutubeResult]) -> ())){

        
        // Create your request
        let task = URLSession.shared.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject] {
                    
                    var results:[YoutubeResult] = []

                    let items = jsonResult["items"] as! [AnyObject]
                    for item in items {
                        let id = item["id"] as! [String:AnyObject]
                        let info = item["snippet"] as! [String:AnyObject]
                        
                        let thumbnails = info["thumbnails"] as! [String:AnyObject]
                        let medium = thumbnails["medium"] as! [String: AnyObject]
                        
                        let videoId = id["videoId"] as! String
                        let title = info["title"] as! String
                        let thumbnailURL_medium = medium["url"] as! String
                        
                        results.append(YoutubeResult(title: title,
                                                          thumbnailURL_medium: thumbnailURL_medium,
                                                          videoId: videoId))
                    }
                    YTResults(results)
                }
            }
            catch {
                print("json error: \(error)")
                YTResults([])
            }
            
        })
        
        // Start the request
        task.resume()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        cell.label.text = results[indexPath.item].title
        cell.imageV.imageFromServerURL(urlString: results[indexPath.item].thumbnailURL_medium)
        cell.id = results[indexPath.item].videoId
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results[indexPath.item]
        let id = result.videoId
        let vc = VideoPlayerController()
        vc.videoId = id
        self.present(vc, animated: true, completion: nil)
    }
    

}

class Cell : UITableViewCell{

    let imageV = UIImageView()
    let label = UILabel()
    var id: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(imageV)
        self.contentView.addSubview(label)
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setConstraints() {
        let views = [
            "imageV" : imageV,
            "label" : label,
            ]
        
        imageV.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[imageV(140)]-[label]-|", options: [], metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageV]|", options: [], metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: [], metrics: nil, views: views))
        
        self.contentView.layoutIfNeeded()
        
    }
    
}

extension UIImageView {
    public func imageFromServerURL(urlString: String) {
        self.image = nil
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                print(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }
}


import YoutubeKit

final class VideoPlayerController: UIViewController {
    
    var player: YTSwiftyPlayer!


    var videoId: String = ""
    
    var button: UIButton = {
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        button.layer.cornerRadius = 25.0
        button.backgroundColor = .gray
        button.setTitle("x", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return button
    }()
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        //for that sweet sweet audio
        NotificationCenter.default.addObserver(self, selector: #selector(someSelector), name: NSNotification.Name("play"), object: nil)
        player = YTSwiftyPlayer(
            frame: CGRect(x: 0, y: 0, width: 640, height: 480),
            playerVars: [.videoID(videoId)])
        
        player.autoplay = true
        
        view = player
        
        player.delegate = self
        
        // gotta close
        view.addSubview(button)

        // load the video
        player.loadPlayer()
        
    
    }
    override func viewWillDisappear(_ animated: Bool) {
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(someSelector), userInfo: nil, repeats: false)
    }
    @objc func someSelector() {
        self.player.playVideo()
    }
    
    

}
extension VideoPlayerController: YTSwiftyPlayerDelegate{
    // ummm so, idk how the video player handles an exit.
    // maybe check into how this dude did the YTSwiftyPlayerState
//    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState){
//        switch state {
//        case .ended, .paused:
//            self.dismiss(animated: true, completion: nil)
//        default:
//            return
//        }
//    }

}

extension String{
    func removeSpaces() -> String{
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
