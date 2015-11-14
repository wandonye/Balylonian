//
// Copyright (c) 2015 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

#import "JSQMessages.h"
#import "RNGridMenu.h"
#import "IQAudioRecorderController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatView : JSQMessagesViewController <RNGridMenuDelegate, UIImagePickerControllerDelegate, IQAudioRecorderControllerDelegate>
//-------------------------------------------------------------------------------------------------------------------------------------------------

@property NSString *groupId;
@property BOOL initialized;
@property Firebase *firebase1;

- (id)initWith:(NSString *)groupId_;
- (void)viewDidLoad;
- (void)updateGroupId:(NSString *)groupId_;
- (BOOL)incoming:(NSDictionary *)item;

- (void)messageSend:(NSString *)text Video:(NSURL *)video Picture:(UIImage *)picture Audio:(NSString *)audio;

@end
