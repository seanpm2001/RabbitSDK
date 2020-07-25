﻿component extends='coldbox.system.testing.BaseTestCase' appMapping='/root'{

/*********************************** LIFE CYCLE Methods ***********************************/

	this.unloadColdBox = false;

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		
		variables.exampleProps={
			'appId':'my app',
			'clusterId':'my cluster',
			'contentEncoding':'UTF-8',
			'contentType':'text/plain',
			'correlationId':'my correlation',
			'deliveryMode':1,
			'expiration':34534534,
			'headers':{
				'header 1' :'value 1',
				'header 2' :'value 2',
				'header 3' :'value 3'
			},
			'messageId':'my message ID',
			'priority':5,
			'replyTo':'my reply to',
			'timestamp':now(),
			'type':'my type'
		};
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	//	getRabbitClient().shutdown();
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		
		describe( 'Rabbitsdk Module', function(){

			beforeEach(function( currentSpec ){
				setup();
			});

			describe( 'Client management', function(){
					
				it( 'should register library', function(){
					var rabbitClient = getRabbitClient();
					expect(	rabbitClient ).toBeComponent();
				});
	
				it( 'should connect to server', function(){
					getRabbitClient().connect( quiet=true );
				});
	
				it( 'should shutdown on preinit', function(){
					getRabbitClient().connect( quiet=true );
					getController().getInterceptorService().processState( 'prereinit' );
				});
	
				it( 'should connect to server', function(){
					var channel = getRabbitClient().createChannel();
					channel.close();
				});
	
				it( 'can have more than one instance', function(){
					getWireBox().getBinder().map( 'PublishClient' ).to( 'rabbitsdk.models.RabbitClient' );
					getWireBox().getBinder().map( 'ConsumerClient' ).to( 'rabbitsdk.models.RabbitClient' );
					
					var publishClient = getRabbitClient( 'PublishClient' );
					var consumerClient = getRabbitClient( 'ConsumerClient' );
					
					expect( publishClient.getClientID() ).notToBe( consumerClient.getClientID() );
					
					publishClient.shutdown();
					consumerClient.shutdown();
				});
					
				it( 'can use auto-closing channels', function(){
					getRabbitClient().batch( (channel)=>channel.queueDeclare( 'myQueue' ) );
				});

				
			});

			describe( 'Queue management', function(){
					
				it( 'can create queue', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).close();
				});
	
				it( 'can bind queue', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queueBind( 'myQueue', 'amq.direct', 'routing.key' ).close();
				});
	
				it( 'can delete queue', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queueDelete( 'myQueue' ).close();
				});
	
				it( 'can purge queue', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' ).close();
				});
	
				it( 'can check if queue exists', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' );
					var exists1 = channel.queueExists( 'myQueue' );
					channel.queueDelete( 'myQueue' );
					var exists2 = channel.queueExists( 'myQueue' );
					var channel.close();
					expect( exists1 ).toBeBoolean();
					expect( exists1 ).toBeTrue();
					expect( exists2 ).toBeFalse();
					
				});
	
				it( 'can get count of messages in queue', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' );
					var count1 = channel.getQueueMessageCount( 'myQueue' );
					channel.publish( 'My Message', 'myQueue' );
					// Publish is async
					sleep(250);
					var count2 = channel.getQueueMessageCount( 'myQueue' );
					
					channel.close();
					expect( count1 ).toBeNumeric();
					expect( count1 ).toBe( 0 );
					expect( count2 ).toBe( 1 );
				});
				
			});

			describe( 'publishing', function(){
					
				it( 'can send a basic string message', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).publish( 'My Message', 'myQueue' ).close();
				});
					
				it( 'can send a message with complex data', function(){
					var data = {
						name:'brad',
						age:40,
						hair:'red',
						likes:[
							'music',
							'computers',
							'procrastinating'
						]
					};
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).publish( data, 'myQueue' ).close();
				});
					
				it( 'can send a message with properties', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' ).publish( 
						body='My Message',
						routingKey='myQueue',
						props=exampleProps
					).close();
				});
				
			});
			describe( 'consuming', function(){
					
				it( 'can consume no message from an empty queue', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' );
					var message = channel.getMessage( 'myQueue' );
					channel.close();
					
					expect( isNull( message ) ).toBeTrue();
				});
					
				it( 'can consume a single message', function(){
					var channel = getRabbitClient()
						.createChannel()
						.queueDeclare( 'myQueue' )
						.publish( 
							body='My Message',
							routingKey='myQueue',
							props=exampleProps
						);
						
					var message = channel.getMessage( 'myQueue' );
					channel.close();
					
					expect( message ).toBeComponent();
					expect( message.getBody() ).toBe( 'My Message' );
					expect( message.getDeliveryTag() ).toBeNumeric();
					expect( message.getExchange() ).toBe( '' );
					expect( message.getRoutingKey() ).toBe( 'myQueue' );
					expect( message.getIsRedeliver() ).toBeBoolean();
		
					expect( message.getAppId() ).toBe( exampleProps.appId );
					expect( message.getClusterId() ).toBe( exampleProps.clusterId );
					expect( message.getContentEncoding() ).toBe( exampleProps.contentEncoding );
					expect( message.getContentType() ).toBe( exampleProps.contentType );
					expect( message.getCorrelationId() ).toBe( exampleProps.correlationId );
					expect( message.getDeliveryMode() ).toBe( exampleProps.deliveryMode );
					expect( message.getExpiration() ).toBe( exampleProps.expiration );
					expect( message.getMessageId() ).toBe( exampleProps.messageId );				
					expect( message.getPriority() ).toBe( exampleProps.priority );
					expect( message.getReplyTo() ).toBe( exampleProps.replyTo );
					expect( message.getTimestamp() ).toBe( exampleProps.timestamp );
					expect( message.getType() ).toBe( exampleProps.type );
					
					
					expect( message.getHeaders() ).toBeStruct();
					expect( message.getHeaders() ).toHaveKey( 'header 1' );
					expect( message.getHeaders() ).toHaveKey( 'header 2' );
					expect( message.getHeaders() ).toHaveKey( 'header 3' );
					expect( message.getHeaders()[ 'header 1' ] ).toBe( 'value 1' );
					expect( message.getHeaders()[ 'header 2' ] ).toBe( 'value 2' );
					expect( message.getHeaders()[ 'header 3' ] ).toBe( 'value 3' );
		
				});
					
				it( 'can consume a single message with no props', function(){
					var channel = getRabbitClient()
						.createChannel()
						.queueDeclare( 'myQueue' )
						.publish( 
							body='My Message',
							routingKey='myQueue'
						);
						
					var message = channel.getMessage( 'myQueue' );
					channel.close();
					
					expect( message ).toBeComponent();
					expect( message.getBody() ).toBe( 'My Message' );
					expect( message.getDeliveryTag() ).toBeNumeric();
					expect( message.getExchange() ).toBe( '' );
					expect( message.getRoutingKey() ).toBe( 'myQueue' );
					expect( message.getIsRedeliver() ).toBeBoolean();
		
					expect( message.getAppId() ).toBe( '' );
					expect( message.getClusterId() ).toBe( '' );
					expect( message.getContentEncoding() ).toBe( '' );
					expect( message.getContentType() ).toBe( '' );
					expect( message.getCorrelationId() ).toBe( '' );
					expect( message.getDeliveryMode() ).toBe( '' );
					expect( message.getExpiration() ).toBe( '' );
					expect( message.getMessageId() ).toBe( '' );				
					expect( message.getPriority() ).toBe( '' );
					expect( message.getReplyTo() ).toBe( '' );
					expect( message.getTimestamp() ).toBe( '' );
					expect( message.getType() ).toBe( '' );
					expect( message.getUserId() ).toBe( '' );
					
					expect( message.getHeaders() ).toBeStruct();
					expect( message.getHeaders() ).toBeEmpty();
		
				});
				
				it( 'can acknowledge a message', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' ).publish( body='My Message', routingKey='myQueue' );
					var message = channel.getMessage( queue='myQueue', autoAcknowledge=false );
					message.acknowledge();
					channel.close();
				});
				
				it( 'can reject a message with no requeue', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' ).publish( body='My Message', routingKey='myQueue' );
					var message = channel.getMessage( queue='myQueue', autoAcknowledge=false );
					message.reject( false );
					// reject is async
					sleep( 250 );
					var count = channel.getQueueMessageCount( 'myQueue' );
					expect( count ).toBe( 0 );
					channel.close();
				});
				
				it( 'can reject a message with a requeue', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' ).publish( body='My Message', routingKey='myQueue' );
					var message = channel.getMessage( queue='myQueue', autoAcknowledge=false );
					message.reject( true );
					// reject is async
					sleep( 250 );
					var count = channel.getQueueMessageCount( 'myQueue' );
					expect( count ).toBe( 1 );
					channel.close();
				});
				
				it( 'can start consumer thread with UDF', function(){
					var channel1 = getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.startConsumer( 
							queue='myQueue',
							autoAcknowledge=false,
							consumer=(message,log)=>{
								log.info( 'Consumer 1 Message received: #message.getBody()#' );
								message.acknowledge();
							} );
							
					var channel2 = getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.startConsumer(
							queue='myQueue',
							autoAcknowledge=false,
							consumer=(message,log)=>{
								log.info( 'Consumer 2 Message received: #message.getBody()#' );
								return true;
							} );
					
					channel1
						.publish( body='Message 1', routingKey='myQueue' )
						.publish( body='Message 2', routingKey='myQueue' )
						.publish( body='Message 3', routingKey='myQueue' )
						.publish( body='Message 4', routingKey='myQueue' )
						.publish( body='Message 5', routingKey='myQueue' )
						.publish( body='Message 6', routingKey='myQueue' );

					sleep(500);
					var count = channel1.getQueueMessageCount( 'myQueue' );
					
					expect( count ).toBe( 0 );
					
					channel1.close();
					channel2.close();
				});
				
				it( 'can start consumer thread with component', function(){
					var channel = getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.startConsumer( 
							queue='myQueue',
							autoAcknowledge=true,
							consumer=new tests.resources.MyConsumer() );
							
					channel
						.publish( body='Message 1', routingKey='myQueue' )
						.publish( body='Message 2', routingKey='myQueue' )
						.publish( body='Message 3', routingKey='myQueue' );

					sleep(250);
					var count = channel.getQueueMessageCount( 'myQueue' );
					
					expect( count ).toBe( 0 );
					
					channel.close();
				});
				
				it( 'can stop consumer thread', function(){
					getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.startConsumer( 'myQueue', ()=>{} )
						.stopConsumer();
				});
				
				it( 'can not start consumer twice on same channel', function(){
					expect( ()=> getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.startConsumer( 'myQueue', ()=>{} )
						.startConsumer( 'myQueue', ()=>{} ) ).toThrow( regex='This channel already has a running consumer' );
				});
				
				it( 'will error if stopping non-existent consumer', function(){
					expect( ()=> getRabbitClient().createChannel().queueDeclare( 'myQueue' )
						.stopConsumer() ).toThrow( regex='There is no consumer currenlty running on this channel' );
				});
					
			});
			describe( 'channel-auto-closing conveience methods', function(){
					
				it( 'can create queue', function(){
					getRabbitClient().queueDeclare( 'myQueue' );
				});
	
				it( 'can bind queue', function(){
					getRabbitClient().queueDeclare( 'myQueue' ).queueBind( 'myQueue', 'amq.direct', 'routing.key' );
				});
	
				it( 'can delete queue', function(){
					getRabbitClient().queueDeclare( 'myQueue' ).queueDelete( 'myQueue' );
				});
	
				it( 'can purge queue', function(){
					getRabbitClient().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' );
				});
	
				it( 'can check if queue exists', function(){
					getRabbitClient().queueDeclare( 'myQueue' );
					var exists1 = getRabbitClient().queueExists( 'myQueue' );
					getRabbitClient().queueDelete( 'myQueue' );
					var exists2 = getRabbitClient().queueExists( 'myQueue' );
					
					expect( exists1 ).toBeBoolean();
					expect( exists1 ).toBeTrue();
					expect( exists2 ).toBeFalse();
					
				});
	
				it( 'can get count of messages in queue', function(){
					getRabbitClient().queueDeclare( 'myQueue' ).queuePurge( 'myQueue' );
					var count1 = getRabbitClient().getQueueMessageCount( 'myQueue' );
					getRabbitClient().publish( 'My Message', 'myQueue' );
					// Publish is async
					sleep(250);
					var count2 = getRabbitClient().getQueueMessageCount( 'myQueue' );
					
					expect( count1 ).toBeNumeric();
					expect( count1 ).toBe( 0 );
					expect( count2 ).toBe( 1 );
				});
					
				it( 'can get a single message', function(){
					getRabbitClient()
						.queueDeclare( 'myQueue' )
						.publish( 'My Message', 'myQueue' );
						
					sleep( 250 );
						
					var message =  getRabbitClient().getMessage( queue='myQueue' );
					
					expect( isNull( message ) ).toBeFalse();
				});
					
				it( 'Cannot use autoAcknowlege as false in this context', function(){
					expect( ()=>getRabbitClient().getMessage( queue='myQueue', autoAcknowledge=false ) ).toThrow( regex='autoAcknowledge cannot be set to false in this method' );
				});
				
			});
		});
	}

	private function getRabbitClient( name='RabbitClient@rabbitsdk' ){
		return getWireBox().getInstance( name );
	}

}