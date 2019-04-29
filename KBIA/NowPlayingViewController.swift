//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit
import SwiftSiriWaveformView

//*****************************************************************
// NowPlayingViewControllerDelegate
//*****************************************************************
protocol NowPlayingViewControllerDelegate: class {
    func didPressPlayingButton()
    func didPressStopButton()
    func didPressNextButton()
    func didPressPreviousButton()
}

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {
    
    weak var delegate: NowPlayingViewControllerDelegate?

    // MARK: - IB UI
    
    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var siriStyleWaveform: SwiftSiriWaveformView!
    
    // MARK: - Properties
    
    var currentStation: RadioStation!
    var currentTrack: Track!
    
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = FRadioPlayer.shared
    
    var mpVolumeSlider: UISlider?
    
    // Siri Wave Properties
    var timer:Timer?
    var rateOfSiriWaveChange:CGFloat = 0.0004
    let siriChangeAmplitudeCeilingPlaying:CGFloat = 0.6
    let siriChangeAmplitudeCeilingStopped:CGFloat = 0.1
    var siriChangeAmplitudeCeiling:CGFloat = 0.05
    let siriChangeAmplitudeFloorPlaying:CGFloat = 0.4
    let siriChangeAmplitudeFloorStopped:CGFloat = 0.06
    var siriChangeAmplitudeFloor:CGFloat = 0.06

    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        //self.title = currentStation.name
        self.title = "Now Playing"
        
        // Set UI
        albumImageView.image = currentTrack.artworkImage
        stationDescLabel.text = currentStation.desc
        stationDescLabel.isHidden = currentTrack.artworkLoaded
        
        // Check for station change
        newStation ? stationDidChange() : playerStateDidChange(radioPlayer.state, animate: false)
        
        
        // Hide / Show Next/Previous buttons
        previousButton.isHidden = hideNextPreviousButtons
        nextButton.isHidden = hideNextPreviousButtons
        
        // Change background to transparent on Siri Waveform
        siriStyleWaveform.backgroundColor = .clear
        
        // Setup Siri Waveform Timer
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.refreshAudioView(_:)), userInfo: nil, repeats: true)
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    
    
    func stationDidChange() {
        radioPlayer.radioURL = URL(string: currentStation.streamURL)
        albumImageView.image = currentTrack.artworkImage
        stationDescLabel.text = currentStation.desc
        stationDescLabel.isHidden = currentTrack.artworkLoaded
//        title = currentStation.name
        title = "Now Playing"
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    // Actions
    
    @IBAction func playingPressed(_ sender: Any) {
        delegate?.didPressPlayingButton()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        delegate?.didPressStopButton()
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        delegate?.didPressNextButton()
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        delegate?.didPressPreviousButton()
    }
    
    //*****************************************************************
    // MARK: - Load station/track
    //*****************************************************************
    
    func load(station: RadioStation?, track: Track?, isNewStation: Bool = true) {
        guard let station = station else { return }
        
        currentStation = station
        currentTrack = track
        newStation = isNewStation
    }
    
    func updateTrackMetadata(with track: Track?) {
        guard let track = track else { return }
        
        currentTrack.artist = track.artist
        currentTrack.title = track.title
        
        updateLabels()
    }
    
    // Update track with new artwork
    func updateTrackArtwork(with track: Track?) {
        guard let track = track else { return }
        
        // Update track struct
        currentTrack.artworkImage = track.artworkImage
        currentTrack.artworkLoaded = track.artworkLoaded
        
        albumImageView.image = currentTrack.artworkImage
        
        if track.artworkLoaded {
            // Animate artwork
            albumImageView.animation = "slideLeft"
            albumImageView.duration = 1
            albumImageView.animate()
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
        }
        
        // Force app to update display
        view.setNeedsDisplay()
    }
    
    private func isPlayingDidChange(_ isPlaying: Bool) {
        playingButton.isSelected = isPlaying
        startNowPlayingAnimation(isPlaying)
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState, animate: Bool) {
        
        let message: String?
        
        switch playbackState {
        case .paused:
            message = "Station Paused..."
            // Tear Down Siri-style waveform
            siriChangeAmplitudeCeiling = siriChangeAmplitudeCeilingStopped
            siriChangeAmplitudeFloor = siriChangeAmplitudeFloorStopped
            siriStyleWaveform.amplitude = siriChangeAmplitudeFloor
            siriStyleWaveform.waveColor = .darkGray
        case .playing:
            message = nil
            // Set Up Siri-style waveform
            siriChangeAmplitudeFloor = siriChangeAmplitudeFloorPlaying
            siriChangeAmplitudeCeiling = siriChangeAmplitudeCeilingPlaying
            siriStyleWaveform.amplitude = siriChangeAmplitudeFloor
            siriStyleWaveform.waveColor = .white
        case .stopped:
            message = "Station Stopped..."
            // Tear Down Siri-style waveform
            siriChangeAmplitudeCeiling = siriChangeAmplitudeCeilingStopped
            siriChangeAmplitudeFloor = siriChangeAmplitudeFloorStopped
            siriStyleWaveform.amplitude = siriChangeAmplitudeFloor
            siriStyleWaveform.waveColor = .darkGray
        }
        
        updateLabels(with: message, animate: false)
        isPlayingDidChange(radioPlayer.isPlaying)
    }
    
    func playerStateDidChange(_ state: FRadioPlayerState, animate: Bool) {
        
        let message: String?
        
        switch state {
        case .loading:
            message = "Loading Station ..."
        case .urlNotSet:
            message = "Station URL not valid"
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(radioPlayer.playbackState, animate: animate)
            return
        case .error:
            message = "Error Playing"
        }
        
        updateLabels(with: message, animate: animate)
    }
    
    //*****************************************************************
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func optimizeForDeviceSize() {
        
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height
        
        if deviceHeight == 480 {
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }
    
    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {

        guard let statusMessage = statusMessage else {
            // Radio is (hopefully) streaming properly
            songLabel.text = currentTrack.title
            artistLabel.text = currentTrack.artist
            shouldAnimateSongLabel(animate)
            return
        }
        
        // There's a an interruption or pause in the audio queue
        
        // Update UI only when it's not aleary updated
        guard songLabel.text != statusMessage else { return }
        
        songLabel.text = statusMessage
        artistLabel.text = currentStation.name
    
        if animate {
            songLabel.animation = "flash"
            songLabel.repeatCount = 1
            songLabel.animate()
        }
    }
    
    // Animations
    
    func shouldAnimateSongLabel(_ animate: Bool) {
        // Animate if the Track has album metadata
        guard animate, currentTrack.title != currentStation.name else { return }
        
        // songLabel animation
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }
    
    @objc internal func refreshAudioView(_:Timer) {
        if self.siriStyleWaveform.amplitude <= self.siriStyleWaveform.idleAmplitude || self.siriStyleWaveform.amplitude > self.siriChangeAmplitudeCeiling {
            self.rateOfSiriWaveChange *= -1
        }
        
        if self.siriStyleWaveform.amplitude < self.siriChangeAmplitudeFloor {
            self.rateOfSiriWaveChange *= -1
        }
        
        // Simply set the amplitude to whatever you need and the view will update itself.
        self.siriStyleWaveform.amplitude += self.rateOfSiriWaveChange
    }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIView.ContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.2
        
        // Create Top BarButton
        let barButton = UIButton(type: .custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
        
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingImageView.startAnimating() : nowPlayingImageView.stopAnimating()
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "InfoDetail", let infoController = segue.destination as? InfoDetailViewController else { return }
        infoController.currentStation = currentStation
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let songToShare = "I'm listening to \(currentTrack.title) on \(currentStation.name) via KBIA Radio"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, currentTrack.artworkImage!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        
        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed:Bool, returnedItems:[Any]?, error: Error?) in
            if completed {
                // do something on completion if you want
            }
        }
        present(activityViewController, animated: true, completion: nil)
    }
}
