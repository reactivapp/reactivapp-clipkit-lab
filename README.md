## Inspiration

We were inspired by the success of online UGC marketing and wanted to bring the consumer voice back into physical retail. Copped ensures every customer has the opportunity to share opinions and earn referrals while helping other shoppers pick out the best items.

Reactiv’s unique value proposition through App Clips inspired us to look beyond traditional mobile apps. Instant rewards in Apple Wallet, on-device AI, and faster conversions from the time limit transform the in-person shopping experience for our Shopify partner stores.

## What it does

Copped pays customers to create video reviews immediately after they purchase a product in-store and shows them to other potential shoppers at the exact moment where they’re deciding what to buy.

Viewer clips: You’re standing in front of a product but want a second opinion. Tap an NFC tag or scan a QR code to instantly watch reviews from other shoppers who just bought it. See what others think and purchase immediately through our Shopify integrations.

Creator clips: You just made a purchase and are loving it. Using your receipt, record a 15-second clip about what you bought and apply effects within the app clip. Earn $5 instantly and another $5 if someone makes a purchase with your recommendation.

No downloads, no login, no wasted time. Just authentic reviews from real buyers and real money for the people making them. 

## How we built it

Our iOS code is built on Reactiv’s ClipKit framework with two separate ClipExperience implementations. The Viewer Clip runs a vertical video feed with AVPlayer looping, where clips are ranked by how many purchases they’ve driven. The Creator Clip is a 7-step wizard that walks you through receipt validation, product selection, and a 5-15 second recording session. Then, we use secure, on-device AI moderation using FoundationModels, add optional text overlays before final review and instant rewards to Apple Wallet.

For video effects, we built a real-time pipeline using AVComposition for color grading (Natural, Rio Heat, Golden Hour, Cool Teal) and CALayer animations for stickers. Text compositing runs through AVVideoCompositionCoreAnimationTool. By using on-device AI, we reduce API costs to ~$0 per clip while maintaining SOTA-level security.

The backend is a live API running on Cloudflare Workers with TypeScript and the Hono framework. A Neon serverless PostgreSQL handles users, clips, receipts, wallets, conversions and transaction logs. Videos are uploaded through Cloudflare R2 Storage using presigned URLS.

The rewards system is fully transactional. You get $5 instantly when you publish a clip, and another $5 gets credited when someone buys because of your video. Shopify webhooks (HMAC-verified) track conversions and trigger Apple Push Notifications if you're still within the 8-hour App Clip window. Apple Wallet ensures users can instantly access their rewards, even after their App Clip expires.

## Challenges we ran into
###Apple Wallet Pass Generation
Getting .pkpass files to actually work ended up taking way longer than we expected. Our first attempt at the wallet pass endpoint returned invalid data that iOS rejected silently, which forced us to rearchitect the whole thing to try the WalletWallet API first, then fall back to local PKCS#12 signing if that didn't work, with much better error reporting so we could actually see what was failing. Even after that, we had to pass the request origin through the conversion flow to generate valid wallet pass URLs. Users can now easily redeem their credits through Apple Wallet

### Video Playback & Hosting
We ran into a non-obvious issue with video playback that took a while to debug. iOS AVPlayer requires HTTP range request support (206 Partial Content) for video streaming, but our initial Cloudflare R2 upload endpoint didn't support byte-range requests. The videos would load but wouldn't actually play in the viewer clip. We had to rebuild the upload and serve pipelines to handle partial content requests properly. On top of that, the looping video player had some race conditions around load readiness that caused clips to stall or skip. Our final implementation can play and scroll through clips effortlessly.
###Rewards Model Redesign

We ended up redesigning the entire reward system twice during the hackathon. We started with a coupon-first model where creators just got discount codes, but it felt weak and didn't really align creator incentives with actual conversions. Halfway through, we decided to pivot to a persistent wallet ledger model with idempotent transactions, wallet codes, and QR-based POS redemption. This implementation preserved strong UX while ensuring vendors and customers are treated fairly.

## Accomplishments that we're proud of
###SwiftUI 6 @Observable Architecture + Liquid Glass Design System
We built the entire iOS app using SwiftUI 6's modern @Observable state management with @Bindable bindings, which made the whole codebase significantly cleaner than the older @StateObject patterns. We also designed and implemented a full custom component library with liquid glass morphism effects, dark mode theming, and a cohesive design system. Everything from glass cards to info chips to step pills follows the same visual language.
###Using the 8-Hour Push Window as a Conversion Reward Channel
This is probably the thing we're most proud of conceptually. Most apps treat the 8-hour App Clip push notification window as just another marketing spam channel. We completely flipped that: it's a time-bound conversion reward system. If your clip drives a purchase within those 8 hours, you get a push notification telling you that you just earned another $5. It turns a hard constraint into a core feature and gives creators immediate feedback when their content actually converts.
###Full-Stack Idempotent Reward Economics
We built a reward system that actually works at scale without getting exploited or falling apart under edge cases. One clip per receipt enforced server-side for anti-fraud, one reward per conversion order deduplicated by unique constraint, and a fully transactional wallet ledger that handles retries and failures gracefully. The economics are straightforward: $5 instant on publish, $5 bonus per conversion, no possibility of lost or duplicated rewards.

## What we learned
###How to Actually Build for App Clips
We learned that App Clips have completely different design constraints than normal apps. No login, no persistent storage assumptions, an 8-hour lifespan, and URL-invoked triggers mean you have to design for ephemerality from the ground up instead of trying to work around it. We learned to think about experiences that fit naturally into that constraint rather than treating it like a limitation. The receipt scan and product scan moments work perfectly as App Clip triggers because they're contextual, immediate, and don't need any setup or account creation.
###Marketing Psychology and Conversion Design
We learned a lot about what actually drives purchase decisions and how to properly convert customers. Watching authentic customer videos from people who just bought the product is way more convincing than polished marketing content. We also learned that immediate financial incentives remove significant barriers to UGC creation. The combination of social proof at the decision moment and instant creator rewards taught us how to align incentives properly.
###Video Production and Color Grading
We learned how to properly color grade and edit video in DaVinci Resolve while putting together our demo video. Learning how to balance color, pace cuts to keep energy up, and show a complete product loop taught us a lot about visual storytelling. We also had to figure out how to make short-form vertical video actually engaging, which is a totally different skill than editing traditional horizontal content.

## What's next for Copped
###Real Merchant Pilots 
We're ready to partner with retail stores in fashion, beauty, and electronics where visual products and authenticity drive purchase decisions. Pilots will help us tune reward amounts and conversion mechanics for different product categories before we scale to hundreds of locations.
###Merchant Analytics & Moderation Tools 
Our next tool is a dashboard so merchants can see which products generate the most UGC, track conversion lift per clip, and manage their reward spend. They will be able to feature top-performing clips, adjust product-specific rewards, and monitor what's driving sales. 